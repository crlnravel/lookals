# Lookals live-location broadcaster

This is the deliberately ephemeral BSD Tour demo server. It relays a current
coordinate between the configured participant slots and owns no tour, quest,
or location history. The public Quick Tunnel is supervised access, not network
privacy: a party that knows the URL can consume the small pending-socket pool
until the ten-second join deadline releases it.

## Run a supervised demo

Generate one token per slot, keep the values server-only, and allow only the
tour/participant pairs being used:

```sh
export DEMO_PARTICIPANT_TOKENS='{"bsd-tour/alice":"'"$(openssl rand -hex 32)"'","bsd-tour/bob":"'"$(openssl rand -hex 32)"'"}'
export ALLOWED_DEMO_ROOMS='["bsd-tour"]'
npm ci
npm start
cloudflared tunnel --url http://localhost:8787
```

Use the emitted HTTPS host as `wss://<host>/v1/tours`. Copy
`Config/LiveLocation.example.xcconfig` to the untracked
`Config/LiveLocation.xcconfig`, then provide one matching participant ID and
token per physical-device build. Stop Node and `cloudflared` after the demo,
discard that local config, and rotate both tokens and the tunnel next time.

Never log tokens, coordinates, or full JSON payloads. The server validates
every text frame against the canonical Draft 2020-12 schema at
`LookalsTests/Resources/LiveLocationProtocol/v1/protocol.schema.json`; the
same files are bundled into `LookalsTests` and are the Swift source of truth.
Valid golden frames are in `v1/frames/*.valid.json`, grouped by protocol type;
negative fixtures use the same names without the `.valid` suffix and are
intentionally rejected by the schema.

## Contract highlights

- UTF-8 text only, 4096-byte payload limit, v1 frames, and strict unknown-key rejection.
- Binary closes with `1003`, malformed JSON with `1007`, and invalid first join/authentication with `1008`.
- A join is acknowledged only by `room.snapshot`; pre-ack location updates are rejected.
- Tokens are compared with a constant-time comparison after tour/participant binding.
- Pending sockets cap at 16, joined sockets at 32, and room participants at 8.
- A location expires after 30 seconds without removing a healthy connection.
- Replacement emits `participant.locationExpired` when needed, never a false `participant.left`.

For deterministic tests, `createRealtimeServer` accepts `clock`, `scheduler`,
`participantTokens`, `allowedRooms`, and cap/deadline/heartbeat overrides.
`start({port: 0})` returns the ephemeral address and `stop()` performs a
bounded graceful shutdown with WebSocket code `1001`.
