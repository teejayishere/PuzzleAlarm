import struct
import hashlib
from pathlib import Path
import zipfile
import unittest
from gate6_decode import decode


def fixture(messages, capacity=4):
    data = bytearray(128 + capacity * 1024)
    struct.pack_into('<10Q', data, 0, 0x3146554236434744, 1, capacity, 1024, 123, len(messages), len(messages), 0, 0, 1)
    for index, message in enumerate(messages):
        payload = message.encode()
        checksum = 2166136261
        for byte in payload + struct.pack('<QQQII', index + 1, index + 100, index + 200, len(payload), 0):
            checksum = ((checksum ^ byte) * 16777619) & 0xffffffff
        offset = 128 + index * 1024
        struct.pack_into('<QQQIIII', data, offset, index + 1, index + 100, index + 200, len(payload), 0, checksum, 0)
        data[offset + 40:offset + 40 + len(payload)] = payload
    return data


class DecoderTests(unittest.TestCase):
    def setUp(self):
        self.data = fixture(['process start uuid=test pid=123', 'probe attached window=test'])

    def test_valid(self):
        self.assertEqual(decode(self.data)['errors'], [])

    def test_payload_corruption(self):
        self.data[128 + 40] ^= 1
        self.assertTrue(decode(self.data)['errors'])

    def test_partial_commit(self):
        struct.pack_into('<Q', self.data, 40, 3)
        self.assertTrue(decode(self.data)['errors'])

    def test_sequence(self):
        struct.pack_into('<Q', self.data, 128 + 1024, 9)
        self.assertTrue(decode(self.data)['errors'])

    def test_missing_attachment(self):
        self.assertTrue(decode(fixture(['process start uuid=test']))['errors'])

    def test_short_file(self):
        with self.assertRaises(ValueError):
            decode(self.data[:-1])

    def gestures(self, count, indices=None):
        return ['process start uuid=test', 'probe attached window=test',
                f'gesture list depth=2 count={count}'] + [
                    f'gesture depth=2 index={i} object=test type=Test state=0 enabled=true'
                    for i in (range(count) if indices is None else indices)]

    def test_more_than_sixteen_gestures_and_empty_snapshot(self):
        messages = self.gestures(80) + ['gesture list depth=3 count=0']
        self.assertEqual(decode(fixture(messages, capacity=len(messages)))['errors'], [])

    def test_valid_bytes_cannot_hide_missing_gesture(self):
        for indices in [range(16), range(79), list(range(40)) + list(range(41, 80)),
                        [0, 0], range(81)]:
            messages = self.gestures(80, indices)
            self.assertTrue(decode(fixture(messages, capacity=len(messages)))['errors'])

    def test_list_interruption_and_missing_summary(self):
        for messages in [self.gestures(2, [0]) + ['touch ended'],
                         self.gestures(0) + ['gesture list depth=2 count=unknown']]:
            self.assertTrue(decode(fixture(messages, capacity=len(messages)))['errors'])
        messages = self.gestures(0)[:2] + self.gestures(1)[3:]
        self.assertIn('gesture missing list', decode(fixture(messages, capacity=len(messages)))['errors'])

    def test_omission_markers_still_fatal(self):
        for marker in ['capture limited gestures', 'capture limited ancestors']:
            messages = self.gestures(0) + [marker]
            self.assertIn('bounded path/gesture capture incomplete',
                          decode(fixture(messages, capacity=len(messages)))['errors'])

    def test_latest_original_archive_remains_incomplete(self):
        archive = Path(__file__).resolve().parents[1] / 'docs/evidence/gate6-single-editor-39185410894/artifact.zip'
        with zipfile.ZipFile(archive) as source:
            raw_names = [n for n in source.namelist() if n.startswith('raw/') and n.endswith('.bin')]
            self.assertEqual(len(raw_names), 1)
            raw = source.read(raw_names[0])
        self.assertEqual(hashlib.sha256(raw).hexdigest(),
                         '97261c2f23316e5fe980043d47a658e3dadd904741af5709701c52a379ca2fe4')
        report = decode(raw)
        self.assertEqual((report['committed'], report['overflow'], report['truncation']), (1374, 0, 0))
        self.assertEqual(sum('capture limited gestures' in r['message'] for r in report['records']), 24)
        self.assertEqual(report['errors'], ['bounded path/gesture capture incomplete'])

    def test_full_buffer_and_string_loss_still_fatal(self):
        for field in (56, 64):
            data = bytearray(self.data)
            struct.pack_into('<Q', data, field, 1)
            self.assertIn('lost/truncated records', decode(data)['errors'])


if __name__ == '__main__':
    unittest.main()
