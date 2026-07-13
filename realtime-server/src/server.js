import http from 'node:http';
import crypto from 'node:crypto';
import { WebSocketServer, WebSocket } from 'ws';
import { ConnectionRegistry, RoomRegistry } from './room-registry.js';
import { encodeFrame, parseText, safeProtocolError, timestamp, isTimestamp, MAX_PAYLOAD_BYTES } from './protocol.js';

const CLOSE = { unsupported: 1003, malformed: 1007, policy: 1008, goingAway: 1001 };
const DEFAULT_JOIN_DEADLINE = 10_000;
const DEFAULT_HEARTBEAT = 10_000;

function clockMs(clock) {
  const v = typeof clock?.now === 'function' ? clock.now() : (typeof clock?.now === 'number' ? clock.now : Date.now());
  return v instanceof Date ? v.getTime() : Number(v);
}
function schedulerOf(scheduler) { return scheduler ?? globalThis; }
function keyFor(tourId, participantId) { return `${tourId}/${participantId}`; }
function tokenFor(tokens, tourId, participantId) {
  const key = keyFor(tourId, participantId);
  if (tokens instanceof Map) return tokens.get(key) ?? tokens.get(tourId)?.get?.(participantId);
  return tokens?.[key] ?? tokens?.[tourId]?.[participantId];
}
function tokenEqual(expected, actual) {
  if (typeof expected !== 'string' || typeof actual !== 'string') return false;
  const a = Buffer.from(expected); const b = Buffer.from(actual);
  const length = Math.max(a.length, b.length);
  const paddedA = Buffer.alloc(length); const paddedB = Buffer.alloc(length);
  a.copy(paddedA); b.copy(paddedB);
  return a.length === b.length && crypto.timingSafeEqual(paddedA, paddedB);
}
function allowedRoom(allowedRooms, tourId) {
  if (!allowedRooms) return true;
  return allowedRooms instanceof Set ? allowedRooms.has(tourId) : Array.isArray(allowedRooms) ? allowedRooms.includes(tourId) : Boolean(allowedRooms[tourId]);
}
function send(socket, frame) { if (socket.readyState === WebSocket.OPEN) socket.send(encodeFrame(frame)); }
function error(socket, code, message = code) { send(socket, safeProtocolError(code, message)); }

export function createRealtimeServer(options = {}) {
  const clock = options.clock ?? { now: () => Date.now() };
  const scheduler = schedulerOf(options.scheduler);
  const roomRegistry = new RoomRegistry({ clock, scheduler, maxParticipantsPerRoom: options.maxParticipantsPerRoom ?? 8, locationTTL: options.locationTTLMs ?? 30_000 });
  const connections = new ConnectionRegistry({ maxPending: options.maxPending ?? 16, maxJoined: options.maxJoined ?? 32, roomRegistry, scheduler });
  const joinDeadline = options.joinDeadlineMs ?? DEFAULT_JOIN_DEADLINE;
  const heartbeatInterval = options.heartbeatIntervalMs ?? DEFAULT_HEARTBEAT;
  const heartbeatSweep = options.heartbeatSweep ?? heartbeatInterval;
  let closing = false;
  let heartbeatHandle;

  const httpServer = http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/healthz') { res.writeHead(200, { 'content-type': 'application/json' }); res.end('{"ok":true}'); return; }
    res.writeHead(404); res.end();
  });
  const wss = new WebSocketServer({ noServer: true, clientTracking: false, maxPayload: MAX_PAYLOAD_BYTES });

  function detach(socket, reason = 'disconnect', closed = false) {
    connections.removePending(socket);
    const peer = connections.joined.get(socket);
    if (peer) {
      connections.removeJoined(socket);
      roomRegistry.detachPeer({ tourId: peer.tourId, participantId: peer.participantId, generation: peer.generation, reason, broadcast: !closing });
    }
    if (closed) connections.removeAccepted(socket);
  }

  function attach(socket) {
    const deadline = scheduler.setTimeout(() => {
      if (!connections.pending.has(socket)) return;
      error(socket, 'unauthorized', 'join deadline expired');
      try { socket.close(CLOSE.policy, 'join deadline expired'); } catch {}
      connections.removePending(socket);
    }, joinDeadline);
    connections.addPending(socket, deadline);
    socket.isAlive = true;
    socket.on('pong', () => { socket.isAlive = true; const peer = connections.joined.get(socket); if (peer) peer.isAlive = true; });
    socket.on('error', () => detach(socket));
    socket.on('close', (_code) => detach(socket, 'disconnect', true));
    socket.on('message', (data, isBinary) => {
      if (!connections.isPending(socket) && !connections.isJoined(socket)) {
        try { socket.close(CLOSE.policy, 'socket is no longer admitted'); } catch {}
        return;
      }
      if (isBinary) { try { socket.close(CLOSE.unsupported, 'binary frames unsupported'); } catch {} return; }
      const parsed = parseText(data.toString());
      if (!parsed.ok) {
        if (parsed.reason === 'too_large') { try { socket.close(1009, 'payload too large'); } catch {} }
        else if (parsed.reason === 'malformed_json') { try { socket.close(CLOSE.malformed, 'malformed JSON'); } catch {} }
        else if (connections.pending.has(socket)) { try { socket.close(CLOSE.policy, 'invalid join'); } catch {} }
        else error(socket, parsed.reason === 'unknown_type' ? 'unknown_type' : 'invalid_schema', 'invalid protocol frame');
        return;
      }
      handleFrame(socket, parsed.frame);
    });
  }

  function handleFrame(socket, frame) {
    const peer = connections.joined.get(socket);
    if (!peer) {
      if (frame.type === 'location.update') { error(socket, 'not_joined', 'room.snapshot acknowledgement is required'); return; }
      if (frame.type !== 'room.join') { try { socket.close(CLOSE.policy, 'join required'); } catch {} return; }
      const existingSlot = roomRegistry.peer(frame.tourId, frame.participantId);
      if (!existingSlot && connections.joinedCount() >= connections.maxJoined) { error(socket, 'unauthorized', 'joined capacity exhausted'); try { socket.close(CLOSE.policy, 'capacity exhausted'); } catch {} return; }
      if (!allowedRoom(options.allowedRooms, frame.tourId) || !tokenEqual(tokenFor(options.participantTokens, frame.tourId, frame.participantId), frame.token)) {
        try { socket.close(CLOSE.policy, 'unauthorized'); } catch {} return;
      }
      const result = roomRegistry.joinPeer({ tourId: frame.tourId, participantId: frame.participantId, socket });
      if (!result.ok) { error(socket, 'unauthorized', result.reason); try { socket.close(CLOSE.policy, result.reason); } catch {} return; }
      if (result.replaced) connections.removeJoined(result.replaced.socket);
      connections.promote(socket, result.peer);
      send(socket, { v: 1, type: 'room.snapshot', serverReceivedAt: timestamp(clockMs(clock)), participants: roomRegistry.snapshot(frame.tourId, frame.participantId) });
      if (result.replaced) { try { result.replaced.socket.close(CLOSE.policy, 'replaced'); } catch {} }
      return;
    }
    if (frame.type !== 'location.update') { error(socket, 'unknown_type', 'unsupported client frame'); return; }
    const now = clockMs(clock);
    if (!Number.isFinite(frame.latitude) || !Number.isFinite(frame.longitude) || Math.abs(frame.latitude) > 90 || Math.abs(frame.longitude) > 180 || frame.accuracyMeters < 0 || frame.accuracyMeters > 50) { error(socket, 'invalid_location', 'location is outside accepted bounds'); return; }
    if (!isTimestamp(frame.observedAt)) { error(socket, 'invalid_location', 'timestamp must be millisecond RFC 3339 UTC'); return; }
    const observed = Date.parse(frame.observedAt);
    if (observed < now - 20_000 || observed > now + 5_000) { error(socket, 'stale_location', 'observedAt is outside the accepted window'); return; }
    if (peer.lastSentAt != null && now - peer.lastSentAt < 1_000) { error(socket, 'rate_limited', 'location updates are limited to one per second'); return; }
    if (peer.location && Math.hypot((frame.latitude - peer.location.latitude) * 111_000, (frame.longitude - peer.location.longitude) * 111_000) < 5 && now - Date.parse(peer.location.serverReceivedAt) < 15_000) { error(socket, 'rate_limited', 'location moved less than 5m'); return; }
    peer.lastSentAt = now;
    roomRegistry.setLocation(peer, { latitude: frame.latitude, longitude: frame.longitude, accuracyMeters: frame.accuracyMeters, observedAt: frame.observedAt, serverReceivedAt: timestamp(now) });
  }

  function startHeartbeat() {
    heartbeatHandle = scheduler.setInterval(() => {
      for (const socket of connections.allSockets()) {
        if (socket.isAlive === false) { const peer = connections.joined.get(socket); detach(socket, 'heartbeat_timeout'); try { socket.terminate(); } catch {}; if (peer) continue; }
        socket.isAlive = false;
        try { socket.ping(); } catch { detach(socket); }
      }
    }, heartbeatSweep);
  }

  httpServer.on('upgrade', (request, socket, head) => {
    if (closing || request.url !== '/v1/tours') { socket.write('HTTP/1.1 404 Not Found\r\n\r\n'); socket.destroy(); return; }
    if (!connections.canAcceptPending()) { socket.write('HTTP/1.1 503 Service Unavailable\r\n\r\n'); socket.destroy(); return; }
    wss.handleUpgrade(request, socket, head, ws => { attach(ws); wss.emit('connection', ws, request); });
  });

  async function start(startOptions = {}) {
    if (typeof startOptions === 'number') startOptions = { port: startOptions };
    const { port = options.port ?? 0, host = options.host ?? '127.0.0.1' } = startOptions;
    if (httpServer.listening) return address();
    closing = false;
    await new Promise((resolve, reject) => { httpServer.once('error', reject); httpServer.listen(port, host, resolve); });
    startHeartbeat();
    return address();
  }
  function address() { const value = httpServer.address(); return typeof value === 'string' ? value : value ? { ...value, wsURL: `ws://${value.address}:${value.port}/v1/tours` } : null; }
  async function stop({ timeoutMs = 2_000 } = {}) {
    if (closing) return;
    closing = true;
    if (heartbeatHandle != null) scheduler.clearInterval(heartbeatHandle);
    for (const socket of connections.allSockets()) { try { socket.close(CLOSE.goingAway, 'server closing'); } catch {} }
    await new Promise(resolve => {
      const done = () => { clearTimeout(timer); resolve(); };
      const timer = setTimeout(done, timeoutMs);
      const check = () => connections.allSockets().length === 0 ? done() : setTimeout(check, 10);
      check();
    });
    for (const socket of connections.allSockets()) { try { socket.terminate(); } catch {} detach(socket, 'disconnect', true); }
    await new Promise(resolve => httpServer.listening ? httpServer.close(resolve) : resolve());
  }
  return { httpServer, wss, roomRegistry, connections, start, stop, address };
}

if (process.argv[1] === new URL(import.meta.url).pathname) {
  const tokens = process.env.DEMO_PARTICIPANT_TOKENS ? JSON.parse(process.env.DEMO_PARTICIPANT_TOKENS) : {};
  const rooms = process.env.ALLOWED_DEMO_ROOMS ? JSON.parse(process.env.ALLOWED_DEMO_ROOMS) : undefined;
  const server = createRealtimeServer({ participantTokens: tokens, allowedRooms: rooms });
  server.start({ port: Number(process.env.PORT ?? 8787), host: process.env.HOST ?? '127.0.0.1' }).then(address => console.log(`realtime server listening on ${address.wsURL}`));
}
