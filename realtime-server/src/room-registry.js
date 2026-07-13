export const DEFAULT_LOCATION_TTL_MS = 30_000;

function nowMs(clock) {
  const value = typeof clock?.now === 'function' ? clock.now() : Date.now();
  return value instanceof Date ? value.getTime() : Number(value);
}

export class RoomRegistry {
  constructor({ clock, scheduler, maxParticipantsPerRoom = 8, locationTTL = DEFAULT_LOCATION_TTL_MS, onEvent } = {}) {
    this.clock = clock ?? { now: () => Date.now() };
    this.scheduler = scheduler ?? globalThis;
    this.maxParticipantsPerRoom = maxParticipantsPerRoom;
    this.locationTTL = locationTTL;
    this.onEvent = onEvent ?? (() => {});
    this.rooms = new Map();
    this.nextGeneration = 1;
  }

  room(tourId) { return this.rooms.get(tourId); }
  peer(tourId, participantId) { return this.rooms.get(tourId)?.get(participantId); }
  joinedCount() { let count = 0; for (const room of this.rooms.values()) count += room.size; return count; }

  joinPeer({ tourId, participantId, socket }) {
    let room = this.rooms.get(tourId);
    if (!room) { room = new Map(); this.rooms.set(tourId, room); }
    const old = room.get(participantId);
    if (!old && room.size >= this.maxParticipantsPerRoom) return { ok: false, reason: 'room_full' };
    if (old?.location) this.broadcast(tourId, { v: 1, type: 'participant.locationExpired', participantId }, old.socket);
    if (old) this.detachPeer({ tourId, participantId, generation: old.generation, reason: 'replaced', broadcast: false, keepRoom: true });
    const peer = {
      tourId, participantId, socket, generation: this.nextGeneration++, isAlive: true,
      location: null, locationRevision: 0, expiresAt: null, expiryHandle: null
    };
    room.set(participantId, peer);
    return { ok: true, peer, replaced: old };
  }

  snapshot(tourId, excludingParticipantId) {
    const room = this.rooms.get(tourId);
    if (!room) return [];
    return [...room.values()]
      .filter(peer => peer.participantId !== excludingParticipantId && peer.location)
      .map(peer => ({ participantId: peer.participantId, ...peer.location }));
  }

  setLocation(peer, location) {
    if (this.peer(peer.tourId, peer.participantId)?.generation !== peer.generation) return false;
    peer.location = location;
    peer.locationRevision += 1;
    const revision = peer.locationRevision;
    const expiresAt = nowMs(this.clock) + this.locationTTL;
    peer.expiresAt = expiresAt;
    if (peer.expiryHandle != null) this.scheduler.clearTimeout(peer.expiryHandle);
    peer.expiryHandle = this.scheduler.setTimeout(() => {
      const current = this.peer(peer.tourId, peer.participantId);
      if (!current || current.generation !== peer.generation || current.locationRevision !== revision || current.expiresAt !== expiresAt) return;
      current.location = null;
      current.expiresAt = null;
      current.expiryHandle = null;
      this.broadcast(peer.tourId, { v: 1, type: 'participant.locationExpired', participantId: peer.participantId }, peer.socket);
      this.onEvent({ type: 'locationExpired', peer });
    }, this.locationTTL);
    this.broadcast(peer.tourId, { v: 1, type: 'participant.location', participantId: peer.participantId, ...location }, peer.socket);
    return true;
  }

  broadcast(tourId, frame, excludedSocket) {
    const room = this.rooms.get(tourId);
    if (!room) return;
    for (const peer of room.values()) {
      if (peer.socket === excludedSocket || peer.socket.readyState !== 1) continue;
      try { peer.socket.send(JSON.stringify(frame)); } catch { /* close/error cleanup owns detach */ }
    }
  }

  detachPeer({ tourId, participantId, generation, reason = 'disconnect', broadcast = true, keepRoom = false }) {
    const room = this.rooms.get(tourId);
    const peer = room?.get(participantId);
    if (!peer || peer.generation !== generation) return false;
    if (peer.expiryHandle != null) this.scheduler.clearTimeout(peer.expiryHandle);
    room.delete(participantId);
    if (room.size === 0 && !keepRoom) this.rooms.delete(tourId);
    if (broadcast && reason !== 'replaced') {
      this.broadcast(tourId, { v: 1, type: 'participant.left', participantId, reason: reason === 'heartbeat_timeout' ? 'heartbeat_timeout' : 'disconnect' });
    }
    this.onEvent({ type: 'detached', peer, reason });
    return true;
  }
}

export class ConnectionRegistry {
  constructor({ maxPending = 16, maxJoined = 32, roomRegistry, scheduler } = {}) {
    this.maxPending = maxPending; this.maxJoined = maxJoined; this.roomRegistry = roomRegistry;
    this.scheduler = scheduler ?? globalThis;
    this.pending = new Map(); this.joined = new Map(); this.accepted = new Map();
  }
  canAcceptPending() { return this.pending.size < this.maxPending; }
  addPending(socket, deadlineHandle) { this.accepted.set(socket, 'pending'); this.pending.set(socket, deadlineHandle); }
  removePending(socket) { const handle = this.pending.get(socket); if (handle != null) this.scheduler.clearTimeout(handle); this.pending.delete(socket); }
  promote(socket, peer) { this.removePending(socket); this.accepted.set(socket, 'joined'); this.joined.set(socket, peer); }
  removeJoined(socket) { this.joined.delete(socket); }
  removeAccepted(socket) { this.removePending(socket); this.removeJoined(socket); this.accepted.delete(socket); }
  isPending(socket) { return this.pending.has(socket); }
  isJoined(socket) { return this.joined.has(socket); }
  allSockets() { return [...this.accepted.keys()]; }
  joinedCount() { return this.joined.size; }
}
