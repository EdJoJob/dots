#!/bin/env python
import sys

SLOW_THRESHOLD = 7


def parse_line(raw_line: bytes):
    nonewline = raw_line.strip(b"\n")
    timestr, rest = nonewline.split(b" ", 1)
    return int(timestr), rest


def main(filename):
    with open(filename, "rb") as f:
        count = 0
        start_time, rest = parse_line(f.readline())
        print("0 {line}".format(line=rest))

        prev_line = rest
        prev_line_start = start_time

        for line in f.readlines():
            count += 1
            if len(line) == 0 or line == b"\n":
                continue
            if not line[0] in b"1234567890":
                continue

            try:
                t, rest = parse_line(line)
                diff = t - prev_line_start
                if diff > SLOW_THRESHOLD:
                    print(
                        "{since_start} {diff} {prev_line}".format(
                            since_start=t - start_time,
                            diff=diff,
                            prev_line=prev_line[:30],
                        )
                    )
                prev_line_start = t
                prev_line = rest
            except ValueError:
                continue


if __name__ == "__main__":
    main(sys.argv[1])
