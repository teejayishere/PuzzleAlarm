"""Conservative accounting: an invocation is never evidence of an executed test."""
import re


def assess(tree, log, method, exit_code):
    nodes = []

    def visit(value):
        if isinstance(value, dict):
            if value.get('nodeType') == 'Test Case' and method in str(value):
                nodes.append(value)
            else:
                for child in value.values():
                    visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)

    visit(tree)
    completed = [n for n in nodes if n.get('result') in ('Passed', 'Failed')]
    starts = len(re.findall(r"Test Case .*" + re.escape(method) + r".* started\.", log))
    executions = max(starts, len(completed))
    failed = any(n.get('result') == 'Failed' for n in completed)
    assertion = bool(re.search(r'XCTAssert|XCTFail|failed -|Asynchronous wait failed', log))
    if executions == 1 and failed and assertion:
        # An assertion establishes an unmet test expectation, not whether the
        # application, XCTest synthesis/querying or platform caused the failure.
        status = 'ASSERTION_FAILURE_CAUSE_UNKNOWN'
    elif exit_code == 0 and len(completed) == 1 and completed[0]['result'] == 'Passed' and executions == 1:
        status = 'SUCCESSFUL_SAMPLE'
    else:
        status = 'TOOLING_FAILURE'
    return dict(executions=executions, completed_tests=len(completed),
                started_log_records=starts, status=status)
