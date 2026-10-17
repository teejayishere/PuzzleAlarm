import unittest
from gate6_accounting import assess

METHOD = 'testExample'
START = "Test Case '-[AlarmManagementUITests testExample]' started."


def tree(result):
    return {'testNodes': [{'nodeType': 'Test Case', 'name': METHOD, 'result': result}]}


class AccountingTests(unittest.TestCase):
    def test_invocation_rejected(self):
        self.assertEqual(assess({}, 'Must specify iterations', METHOD, 64)['executions'], 0)
        self.assertEqual(assess({}, '', METHOD, 64)['status'], 'TOOLING_FAILURE')

    def test_empty_green_is_not_sample(self):
        self.assertEqual(assess({'testNodes': []}, '', METHOD, 0)['status'], 'TOOLING_FAILURE')

    def test_pass(self):
        self.assertEqual(assess(tree('Passed'), START, METHOD, 0)['status'], 'SUCCESSFUL_SAMPLE')

    def test_captured_assertion(self):
        self.assertEqual(assess(tree('Failed'), START + '\nXCTAssertEqual failed', METHOD, 65)['status'], 'PRODUCT_FAILURE')

    def test_runner_failure_is_not_product_failure(self):
        self.assertEqual(assess(tree('Failed'), START + '\nRunner crashed', METHOD, 65)['status'], 'TOOLING_FAILURE')

    def test_interrupted_execution(self):
        result = assess({}, START, METHOD, None)
        self.assertEqual(result['executions'], 1)
        self.assertEqual(result['completed_tests'], 0)
        self.assertEqual(result['status'], 'TOOLING_FAILURE')

    def test_repeated_execution_rejected(self):
        self.assertEqual(assess(tree('Passed'), START + '\n' + START, METHOD, 0)['status'], 'TOOLING_FAILURE')


if __name__ == '__main__':
    unittest.main()
