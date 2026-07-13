import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import Ajv2020 from 'ajv/dist/2020.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const defaultProtocolDirectory = path.resolve(here, '../../LookalsTests/Resources/LiveLocationProtocol/v1');
export const MAX_PAYLOAD_BYTES = 4096;
export const TIMESTAMP_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;

export function protocolDirectory(directory = process.env.LIVE_LOCATION_PROTOCOL_DIR ?? defaultProtocolDirectory) {
  return directory;
}

export function loadProtocolSchema(directory = protocolDirectory()) {
  return JSON.parse(fs.readFileSync(path.join(directory, 'protocol.schema.json'), 'utf8'));
}

const ajv = new Ajv2020({ allErrors: false, strict: true });
let validator;
function getValidator() {
  if (!validator) validator = ajv.compile(loadProtocolSchema());
  return validator;
}

export function validateFrame(frame) {
  const valid = getValidator()(frame);
  return { valid: Boolean(valid), errors: valid ? [] : (getValidator().errors ?? []) };
}

export function parseText(text) {
  if (typeof text !== 'string' || Buffer.byteLength(text, 'utf8') > MAX_PAYLOAD_BYTES) {
    return { ok: false, reason: 'too_large' };
  }
  let frame;
  try { frame = JSON.parse(text); } catch { return { ok: false, reason: 'malformed_json' }; }
  const knownTypes = new Set(['room.join', 'room.snapshot', 'location.update', 'participant.location', 'participant.locationExpired', 'participant.left', 'protocol.error']);
  if (frame && typeof frame === 'object' && !Array.isArray(frame) && typeof frame.type === 'string' && !knownTypes.has(frame.type)) {
    return { ok: false, reason: 'unknown_type' };
  }
  const result = validateFrame(frame);
  return result.valid ? { ok: true, frame } : { ok: false, reason: 'invalid_schema', errors: result.errors };
}

export function encodeFrame(frame) {
  const result = validateFrame(frame);
  if (!result.valid) throw new TypeError('Cannot encode a schema-invalid protocol frame');
  return JSON.stringify(frame);
}

export function isTimestamp(value) {
  if (typeof value !== 'string' || !TIMESTAMP_RE.test(value)) return false;
  const parsed = Date.parse(value);
  return !Number.isNaN(parsed) && new Date(parsed).toISOString() === value;
}

export function timestamp(ms) {
  return new Date(ms).toISOString();
}

export function safeProtocolError(code, message = code) {
  return { v: 1, type: 'protocol.error', code, message };
}
