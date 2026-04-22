import re
import sys

text = sys.stdin.read()

failure = re.search(r"FAIL: (.*)", text)
values = re.findall(r"(\d+) != (\d+)", text)

if failure and values:
    issue = failure.group(1)
    actual, expected = values[0]

    print("\n🧾 AUTO AUDIT REPORT")
    print("----------------------")
    print(f"Issue: {issue}")
    print(f"Observed: {actual}")
    print(f"Expected: {expected}")

    if int(actual) > int(expected):
        print("\n🔴 Likely bug class: ACCOUNTING INFLATION")
        print("Suggested fix:")
        print("""
- Move state updates before external calls (CEI pattern)
- Add reentrancy guard (nonReentrant)
- Ensure mint is idempotent per tx context
""")
