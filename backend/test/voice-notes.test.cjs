const test = require("node:test");
const assert = require("node:assert/strict");
const {
  VoiceNoteStorage,
} = require("../dist/src/modules/messages/voice-note.storage");

const storage = new VoiceNoteStorage({ getOrThrow: () => "test" });
const m4a = (size = 2048) => {
  const buffer = Buffer.alloc(size);
  buffer.write("ftypM4A ", 4, "ascii");
  return { buffer, size };
};

test("accepts an m4a clip and rounds its reported length", () => {
  assert.equal(storage.assertValid(m4a(), "12345.6"), 12346);
});

test("rejects files that are not m4a audio", () => {
  const notAudio = { buffer: Buffer.alloc(2048), size: 2048 };
  assert.throws(() => storage.assertValid(notAudio, 5000), /voice message/i);
  assert.throws(() => storage.assertValid(undefined, 5000), /voice message/i);
});

test("rejects clips that are too short, too long or too large", () => {
  assert.throws(() => storage.assertValid(m4a(), 100), /2 minutes/);
  assert.throws(() => storage.assertValid(m4a(), 5 * 60 * 1000), /2 minutes/);
  assert.throws(() => storage.assertValid(m4a(), "abc"), /2 minutes/);
  assert.throws(
    () => storage.assertValid(m4a(6 * 1024 * 1024), 5000),
    /voice message/i,
  );
});
