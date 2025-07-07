#!/usr/bin/env python3

import os
import sys

def main():
    # Read POST body (required to consume it, even if we ignore it)
    content_length = int(os.environ.get('CONTENT_LENGTH', 0))
    _ = sys.stdin.read(content_length)

    # HTTP headers
--    print("Status: 200 OK")
    print("Content-Type: application/json")
    print()  # End of headers

    # Fixed response payload
    print('{"status": "ok", "message": "Post received"}')

if __name__ == "__main__":
    main()
