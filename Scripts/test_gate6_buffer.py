import struct
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


if __name__ == '__main__':
    unittest.main()
