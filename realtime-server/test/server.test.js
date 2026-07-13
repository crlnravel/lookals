import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import WebSocket from 'ws';
import { createRealtimeServer } from '../src/server.js';
import { encodeFrame, validateFrame } from '../src/protocol.js';
import { ConnectionRegistry, RoomRegistry } from '../src/room-registry.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../LookalsTests/Resources/LiveLocationProtocol/v1/frames');
const frameFiles = fs.readdirSync(root).filter(name => name.endsWith('.valid.json'));

function connect(url) {
  return new Promise((resolve, reject) => {
    const socket = new WebSocket(url);
    socket.once('open', () => resolve(socket));
    socket.once('error', reject);
  });
}
function nextMessage(socket) {
  return new Promise((resolve, reject) => {
    const onMessage = data => { cleanup(); resolve(JSON.parse(data.toString())); };
    const onError = error => { cleanup(); reject(error); };
    const cleanup = () => { socket.off('message', onMessage); socket.off('error', onError); };
    socket.on('message', onMessage); socket.on('error', onError);
  });
}
function nextClose(socket) {
  return new Promise(resolve => {
    if (socket.readyState === WebSocket.CLOSED) resolve(undefined);
    else socket.once('close', code => resolve(code));
  });
}
async function waitFor(predicate, timeoutMs = 500) {
  const end = Date.now() + timeoutMs;
  while (!predicate() && Date.now() < end) await new Promise(resolve => setTimeout(resolve, 5));
  assert.equal(predicate(), true, 'condition did not become true before timeout');
}
function close(socket) { return new Promise(resolve => { if (socket.readyState === WebSocket.CLOSED) resolve(); else socket.once('close', resolve); socket.close(); }); }

class FakeScheduler {
  constructor() { this.now = 0; this.tasks = []; this.next = 1; }
  setTimeout(fn, delay) { const task = { id: this.next++, at: this.now + delay, fn, interval: 0 }; this.tasks.push(task); return task.id; }
  clearTimeout() { /* deliberately retain callbacks so generation guards are exercised */ }
  setInterval(fn, delay) { const task = { id: this.next++, at: this.now + delay, fn, interval: delay }; this.tasks.push(task); return task.id; }
  clearInterval(id) { this.tasks = this.tasks.filter(task => task.id !== id); }
  advance(milliseconds) {
    this.now += milliseconds;
    while (true) {
      const due = this.tasks.filter(task => task.at <= this.now).sort((a, b) => a.at - b.at)[0];
      if (!due) break;
      if (due.interval) due.at += due.interval; else this.tasks = this.tasks.filter(task => task !== due);
      due.fn();
    }
  }
}

test('canonical valid fixtures validate from the shared resource directory', () => {
  assert.deepEqual(frameFiles.sort(), [
    'location.update.valid.json', 'participant.left.valid.json', 'participant.location.valid.json',
    'participant.locationExpired.valid.json', 'protocol.error.valid.json', 'room.join.valid.json', 'room.snapshot.valid.json'
  ]);
  for (const file of frameFiles) {
    const raw = fs.readFileSync(path.join(root, file), 'utf8').trim();
    const frame = JSON.parse(raw);
    assert.equal(validateFrame(frame).valid, true, file);
    assert.equal(encodeFrame(frame), raw, `${file} canonical bytes`);
  }
});

test('negative fixtures reject unknown keys and timestamp shapes', () => {
  const negativeFiles = fs.readdirSync(root).filter(name => name.endsWith('.json') && !name.endsWith('.valid.json'));
  assert.deepEqual(negativeFiles.sort(), ['location.update.bad-timestamp.json', 'participant.location.nested-unknown.json', 'room.join.unknown-key.json']);
  for (const file of negativeFiles) assert.equal(validateFrame(JSON.parse(fs.readFileSync(path.join(root, file), 'utf8'))).valid, false, file);
});

test('health, join snapshot, sender exclusion, and room isolation', async t => {
  const server = createRealtimeServer({ participantTokens: { 'bsd-tour/alice': 'a', 'bsd-tour/bob': 'b', 'other/carol': 'c' }, allowedRooms: ['bsd-tour', 'other'] });
  const address = await server.start();
  t.after(() => server.stop());
  const health = await fetch(`http://127.0.0.1:${address.port}/healthz`);
  assert.equal(health.status, 200);
  const alice = await connect(address.wsURL); const bob = await connect(address.wsURL); const carol = await connect(`ws://127.0.0.1:${address.port}/v1/tours`);
  alice.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'alice', token: 'a' }));
  assert.equal((await nextMessage(alice)).type, 'room.snapshot');
  bob.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'bob', token: 'b' }));
  assert.deepEqual((await nextMessage(bob)).participants, []);
  carol.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'other', participantId: 'carol', token: 'c' }));
  await nextMessage(carol);
  const received = nextMessage(bob);
  alice.send(JSON.stringify({ v: 1, type: 'location.update', latitude: -6.17, longitude: 106.82, accuracyMeters: 10, observedAt: new Date().toISOString() }));
  const location = await received;
  assert.equal(location.type, 'participant.location'); assert.equal(location.participantId, 'alice');
  assert.equal(carol.listenerCount('message'), 0);
  await Promise.all([close(alice), close(bob), close(carol)]);
});

test('sole-participant replacement keeps the active room map attached', () => {
  const scheduler = new FakeScheduler();
  const socketA = { readyState: 1, send() {} };
  const socketB = { readyState: 1, send() {} };
  const registry = new RoomRegistry({ clock: scheduler, scheduler });
  const first = registry.joinPeer({ tourId: 'bsd-tour', participantId: 'alice', socket: socketA });
  const replacement = registry.joinPeer({ tourId: 'bsd-tour', participantId: 'alice', socket: socketB });
  assert.equal(replacement.ok, true);
  assert.equal(registry.peer('bsd-tour', 'alice'), replacement.peer);
  assert.equal(registry.setLocation(replacement.peer, { latitude: 1, longitude: 1, accuracyMeters: 1, observedAt: '1970-01-01T00:00:00.000Z', serverReceivedAt: '1970-01-01T00:00:00.000Z' }), true);
  assert.equal(registry.detachPeer({ tourId: 'bsd-tour', participantId: 'alice', generation: first.peer.generation }), false);
  assert.equal(registry.detachPeer({ tourId: 'bsd-tour', participantId: 'alice', generation: replacement.peer.generation }), true);
  assert.equal(registry.room('bsd-tour'), undefined);
});

test('accepted, pending, and joined counts retain ownership until close cleanup', () => {
  const registry = new ConnectionRegistry({ maxPending: 2, maxJoined: 2, scheduler: new FakeScheduler() });
  const socket = {};
  registry.addPending(socket, 1);
  assert.equal(registry.pending.size, 1);
  assert.equal(registry.joined.size, 0);
  assert.equal(registry.allSockets().length, 1);
  registry.removePending(socket);
  assert.equal(registry.pending.size, 0);
  assert.equal(registry.allSockets().length, 1);
  registry.promote(socket, { generation: 1 });
  assert.equal(registry.joined.size, 1);
  assert.equal(registry.allSockets().length, 1);
  registry.removeJoined(socket);
  assert.equal(registry.joined.size, 0);
  assert.equal(registry.allSockets().length, 1);
  registry.removeAccepted(socket);
  assert.equal(registry.allSockets().length, 0);
});

test('replacement expires location without emitting a false leave', async t => {
  const server = createRealtimeServer({ participantTokens: { 'bsd-tour/alice': 'a', 'bsd-tour/bob': 'b' } });
  const address = await server.start(); t.after(() => server.stop());
  const oldAlice = await connect(address.wsURL); const bob = await connect(address.wsURL);
  oldAlice.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'alice', token: 'a' })); await nextMessage(oldAlice);
  bob.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'bob', token: 'b' })); await nextMessage(bob);
  oldAlice.send(JSON.stringify({ v: 1, type: 'location.update', latitude: 1, longitude: 1, accuracyMeters: 1, observedAt: new Date().toISOString() }));
  await nextMessage(bob);
  const replacementEvent = nextMessage(bob);
  const newAlice = await connect(address.wsURL);
  newAlice.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'alice', token: 'a' }));
  const event = await replacementEvent;
  assert.equal(event.type, 'participant.locationExpired'); assert.equal(event.participantId, 'alice');
  assert.equal((await nextMessage(newAlice)).type, 'room.snapshot');
  assert.equal(server.connections.joinedCount(), 2);
  assert.equal(server.connections.allSockets().length, 3, 'retired socket remains owned until its close event');
  if (oldAlice.readyState === WebSocket.OPEN) {
    oldAlice.send(JSON.stringify({ v: 1, type: 'location.update', latitude: 9, longitude: 9, accuracyMeters: 1, observedAt: new Date().toISOString() }));
  }
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(server.roomRegistry.peer('bsd-tour', 'alice').location, null, 'retired socket cannot publish into replacement generation');
  await close(oldAlice);
  assert.equal(server.connections.allSockets().length, 2);
  await Promise.all([close(newAlice), close(bob)]);
});

test('strict errors reject malformed and binary frames', async t => {
  const server = createRealtimeServer({ participantTokens: { 'bsd-tour/alice': 'a' } });
  const address = await server.start(); t.after(() => server.stop());
  const malformed = await connect(address.wsURL);
  const malformedClose = new Promise(resolve => malformed.once('close', (code) => resolve(code)));
  malformed.send('{'); assert.equal(await malformedClose, 1007);
  const binary = await connect(address.wsURL);
  const binaryClose = new Promise(resolve => binary.once('close', (code) => resolve(code)));
  binary.send(Buffer.from('x')); assert.equal(await binaryClose, 1003);
  const oversized = await connect(address.wsURL);
  const oversizedClose = new Promise(resolve => oversized.once('close', (code) => resolve(code)));
  oversized.send('x'.repeat(4097)); assert.equal(await oversizedClose, 1009);
});

test('pre-ack, schema, location-window, and rate errors are recoverable', async t => {
  const server = createRealtimeServer({ participantTokens: { 'bsd-tour/alice': 'a' } });
  const address = await server.start(); t.after(() => server.stop());
  const socket = await connect(address.wsURL);
  socket.send(JSON.stringify({ v: 1, type: 'location.update', latitude: 1, longitude: 1, accuracyMeters: 1, observedAt: new Date().toISOString() }));
  assert.equal((await nextMessage(socket)).code, 'not_joined');
  socket.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'alice', token: 'a' }));
  await nextMessage(socket);
  socket.send(JSON.stringify({ v: 1, type: 'unsupported.frame' }));
  assert.equal((await nextMessage(socket)).code, 'unknown_type');
  socket.send(JSON.stringify({ v: 1, type: 'location.update', latitude: 1, longitude: 1, accuracyMeters: 1, observedAt: new Date().toISOString(), extra: true }));
  assert.equal((await nextMessage(socket)).code, 'invalid_schema');
  socket.send(JSON.stringify({ v: 1, type: 'location.update', latitude: 91, longitude: 1, accuracyMeters: 1, observedAt: new Date().toISOString() }));
  assert.equal((await nextMessage(socket)).code, 'invalid_schema');
  socket.send(JSON.stringify({ v: 1, type: 'location.update', latitude: 1, longitude: 1, accuracyMeters: 1, observedAt: new Date(Date.now() + 30_000).toISOString() }));
  assert.equal((await nextMessage(socket)).code, 'stale_location');
  socket.send(JSON.stringify({ v: 1, type: 'location.update', latitude: 1, longitude: 1, accuracyMeters: 1, observedAt: new Date().toISOString() }));
  socket.send(JSON.stringify({ v: 1, type: 'location.update', latitude: 1.001, longitude: 1.001, accuracyMeters: 1, observedAt: new Date().toISOString() }));
  assert.equal((await nextMessage(socket)).code, 'rate_limited');
  await close(socket);
});

test('token, room, and participant binding failures close with policy violation', async t => {
  const server = createRealtimeServer({ participantTokens: { 'bsd-tour/alice': 'a' }, allowedRooms: ['bsd-tour'] });
  const address = await server.start(); t.after(() => server.stop());
  for (const join of [
    { tourId: 'bsd-tour', participantId: 'alice', token: 'wrong' },
    { tourId: 'other', participantId: 'alice', token: 'a' },
    { tourId: 'bsd-tour', participantId: 'bob', token: 'a' }
  ]) {
    const socket = await connect(address.wsURL);
    const closed = nextClose(socket);
    socket.send(JSON.stringify({ v: 1, type: 'room.join', ...join }));
    assert.equal(await closed, 1008);
  }
});

test('pending cap recovers after join deadlines and room/global caps admit only replacements', async t => {
  const server = createRealtimeServer({
    participantTokens: { 'bsd-tour/alice': 'a', 'bsd-tour/bob': 'b' },
    joinDeadlineMs: 30,
    maxPending: 16,
    maxJoined: 1,
    maxParticipantsPerRoom: 1
  });
  const address = await server.start(); t.after(() => server.stop());
  const pending = await Promise.all(Array.from({ length: 16 }, () => connect(address.wsURL)));
  assert.equal(server.connections.pending.size, 16);
  assert.equal(server.connections.allSockets().length, 16);
  await assert.rejects(connect(address.wsURL));
  await Promise.all(pending.map(nextClose));
  assert.equal(server.connections.pending.size, 0);
  await waitFor(() => server.connections.allSockets().length === 0);
  const alice = await connect(address.wsURL);
  alice.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'alice', token: 'a' }));
  await nextMessage(alice);
  const bob = await connect(address.wsURL);
  const bobClosed = nextClose(bob);
  bob.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'bob', token: 'b' }));
  assert.equal(await bobClosed, 1008);
  const replacement = await connect(address.wsURL);
  replacement.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'alice', token: 'a' }));
  await nextMessage(replacement);
  assert.equal(server.connections.joinedCount(), 1);
  await Promise.all([close(alice), close(replacement)]);
});

test('injected scheduler cannot let an old expiry clear a refreshed coordinate', () => {
  const scheduler = new FakeScheduler();
  const sent = [];
  const socket = { readyState: 1, send: value => sent.push(JSON.parse(value)) };
  const observer = { readyState: 1, send: value => sent.push(JSON.parse(value)) };
  const registry = new RoomRegistry({ clock: scheduler, scheduler });
  const joined = registry.joinPeer({ tourId: 'bsd-tour', participantId: 'alice', socket });
  assert.equal(joined.ok, true);
  assert.equal(registry.joinPeer({ tourId: 'bsd-tour', participantId: 'bob', socket: observer }).ok, true);
  const location = (latitude, serverReceivedAt) => ({ latitude, longitude: 1, accuracyMeters: 1, observedAt: serverReceivedAt, serverReceivedAt });
  registry.setLocation(joined.peer, location(1, '1970-01-01T00:00:00.000Z'));
  scheduler.advance(29_000);
  registry.setLocation(joined.peer, location(2, '1970-01-01T00:00:29.000Z'));
  scheduler.advance(1_000);
  assert.equal(registry.peer('bsd-tour', 'alice').location.latitude, 2);
  scheduler.advance(28_000);
  assert.equal(registry.peer('bsd-tour', 'alice').location.latitude, 2);
  scheduler.advance(1_000);
  assert.equal(registry.peer('bsd-tour', 'alice').location, null);
  assert.equal(sent.filter(frame => frame.type === 'participant.locationExpired').length, 1);
});

test('expired location keeps the peer joined, then genuine close emits one leave', async t => {
  const server = createRealtimeServer({ participantTokens: { 'bsd-tour/alice': 'a', 'bsd-tour/bob': 'b' }, locationTTLMs: 25 });
  const address = await server.start(); t.after(() => server.stop());
  const alice = await connect(address.wsURL); const bob = await connect(address.wsURL);
  alice.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'alice', token: 'a' })); await nextMessage(alice);
  bob.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'bob', token: 'b' })); await nextMessage(bob);
  const location = nextMessage(bob);
  alice.send(JSON.stringify({ v: 1, type: 'location.update', latitude: 1, longitude: 1, accuracyMeters: 1, observedAt: new Date().toISOString() }));
  assert.equal((await location).type, 'participant.location');
  assert.equal(server.connections.joinedCount(), 2);
  assert.equal((await nextMessage(bob)).type, 'participant.locationExpired');
  assert.equal(server.connections.joinedCount(), 2);
  const left = nextMessage(bob);
  await close(alice);
  assert.deepEqual(await left, { v: 1, type: 'participant.left', participantId: 'alice', reason: 'disconnect' });
  await close(bob);
});

test('heartbeat timeout detaches a dead peer with a stable reason', async t => {
  const scheduler = new FakeScheduler();
  const server = createRealtimeServer({
    clock: { now: () => scheduler.now },
    scheduler,
    heartbeatSweep: 10,
    heartbeatIntervalMs: 10,
    participantTokens: { 'bsd-tour/alice': 'a', 'bsd-tour/bob': 'b' }
  });
  const address = await server.start(); t.after(() => server.stop());
  const alice = await connect(address.wsURL); const bob = await connect(address.wsURL);
  alice.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'alice', token: 'a' })); await nextMessage(alice);
  bob.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'bob', token: 'b' })); await nextMessage(bob);
  const [serverAlice] = server.connections.joined.keys();
  serverAlice.isAlive = false;
  const left = nextMessage(bob);
  scheduler.advance(10);
  assert.deepEqual(await left, { v: 1, type: 'participant.left', participantId: 'alice', reason: 'heartbeat_timeout' });
  await nextClose(alice);
  assert.equal(server.connections.joinedCount(), 1);
  await close(bob);
});

test('stop then start creates an empty ephemeral server', async t => {
  const server = createRealtimeServer({ participantTokens: { 'bsd-tour/alice': 'a' } });
  const first = await server.start();
  await server.stop();
  const second = await server.start();
  t.after(() => server.stop());
  assert.equal(typeof first.port, 'number'); assert.equal(typeof second.port, 'number');
  const socket = await connect(second.wsURL);
  socket.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'alice', token: 'a' }));
  assert.deepEqual((await nextMessage(socket)).participants, []);
  await close(socket);
});

test('graceful shutdown closes both joined and pending sockets and clears ownership', async () => {
  const server = createRealtimeServer({ participantTokens: { 'bsd-tour/alice': 'a' } });
  const address = await server.start();
  const joined = await connect(address.wsURL);
  joined.send(JSON.stringify({ v: 1, type: 'room.join', tourId: 'bsd-tour', participantId: 'alice', token: 'a' }));
  await nextMessage(joined);
  const pending = await connect(address.wsURL);
  const joinedClosed = nextClose(joined); const pendingClosed = nextClose(pending);
  await server.stop();
  assert.equal(await joinedClosed, 1001);
  assert.equal(await pendingClosed, 1001);
  assert.equal(server.connections.allSockets().length, 0);
  assert.equal(server.roomRegistry.rooms.size, 0);
});
