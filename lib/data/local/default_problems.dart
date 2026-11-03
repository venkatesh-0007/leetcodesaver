import '../models/difficulty.dart';
import '../models/saved_problem.dart';

class DefaultProblems {
  static List<SavedProblem> getInitialProblems() {
    final now = DateTime.now().subtract(const Duration(days: 30));

    return [
      SavedProblem(
        leetCodeId: 1,
        title: 'Two Sum',
        slug: 'two-sum',
        url: 'https://leetcode.com/problems/two-sum/',
        difficulty: Difficulty.easy,
        language: 'Python 3',
        sourceCode: '''class Solution:
    def twoSum(self, nums: List[int], target: int) -> List[int]:
        seen = {}
        for i, num in enumerate(nums):
            complement = target - num
            if complement in seen:
                return [seen[complement], i]
            seen[num] = i
        return []''',
        isAccepted: true,
        dateAdded: now.subtract(const Duration(days: 20)),
        lastSubmittedDate: DateTime.now().subtract(const Duration(days: 9)),
        submissionAttempts: 1,
        notes: 'Classic hash map solution with O(n) time and O(n) space.',
      ),
      SavedProblem(
        leetCodeId: 20,
        title: 'Valid Parentheses',
        slug: 'valid-parentheses',
        url: 'https://leetcode.com/problems/valid-parentheses/',
        difficulty: Difficulty.easy,
        language: 'Python 3',
        sourceCode: '''class Solution:
    def isValid(self, s: str) -> bool:
        stack = []
        mapping = {')': '(', '}': '{', ']': '['}
        for char in s:
            if char in mapping:
                top_element = stack.pop() if stack else '#'
                if mapping[char] != top_element:
                    return False
            else:
                stack.append(char)
        return not stack''',
        isAccepted: true,
        dateAdded: now.subtract(const Duration(days: 15)),
        lastSubmittedDate: DateTime.now().subtract(const Duration(days: 12)),
        submissionAttempts: 1,
        notes: 'Stack based bracket matching.',
      ),
      SavedProblem(
        leetCodeId: 21,
        title: 'Merge Two Sorted Lists',
        slug: 'merge-two-sorted-lists',
        url: 'https://leetcode.com/problems/merge-two-sorted-lists/',
        difficulty: Difficulty.easy,
        language: 'Java',
        sourceCode: '''class Solution {
    public ListNode mergeTwoLists(ListNode list1, ListNode list2) {
        ListNode dummy = new ListNode(0);
        ListNode current = dummy;
        
        while (list1 != null && list2 != null) {
            if (list1.val <= list2.val) {
                current.next = list1;
                list1 = list1.next;
            } else {
                current.next = list2;
                list2 = list2.next;
            }
            current = current.next;
        }
        
        if (list1 != null) current.next = list1;
        if (list2 != null) current.next = list2;
        
        return dummy.next;
    }
}''',
        isAccepted: true,
        dateAdded: now.subtract(const Duration(days: 14)),
        lastSubmittedDate: DateTime.now().subtract(const Duration(days: 8)),
        submissionAttempts: 2,
        notes: 'Two pointer linked list merge with dummy node.',
      ),
      SavedProblem(
        leetCodeId: 121,
        title: 'Best Time to Buy and Sell Stock',
        slug: 'best-time-to-buy-and-sell-stock',
        url: 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/',
        difficulty: Difficulty.easy,
        language: 'Python 3',
        sourceCode: '''class Solution:
    def maxProfit(self, prices: List[int]) -> int:
        min_price = float('inf')
        max_profit = 0
        for price in prices:
            if price < min_price:
                min_price = price
            elif price - min_price > max_profit:
                max_profit = price - min_price
        return max_profit''',
        isAccepted: true,
        dateAdded: now.subtract(const Duration(days: 10)),
        lastSubmittedDate: null,
        submissionAttempts: 0,
        notes: 'Single pass tracking minimum price seen so far.',
      ),
      SavedProblem(
        leetCodeId: 206,
        title: 'Reverse Linked List',
        slug: 'reverse-linked-list',
        url: 'https://leetcode.com/problems/reverse-linked-list/',
        difficulty: Difficulty.easy,
        language: 'C++',
        sourceCode: '''class Solution {
public:
    ListNode* reverseList(ListNode* head) {
        ListNode* prev = nullptr;
        ListNode* curr = head;
        while (curr != nullptr) {
            ListNode* nextTemp = curr->next;
            curr->next = prev;
            prev = curr;
            curr = nextTemp;
        }
        return prev;
    }
};''',
        isAccepted: true,
        dateAdded: now.subtract(const Duration(days: 8)),
        lastSubmittedDate: null,
        submissionAttempts: 0,
        notes: 'Iterative 3-pointer linked list reversal.',
      ),
      SavedProblem(
        leetCodeId: 53,
        title: 'Maximum Subarray',
        slug: 'maximum-subarray',
        url: 'https://leetcode.com/problems/maximum-subarray/',
        difficulty: Difficulty.medium,
        language: 'Python 3',
        sourceCode: '''class Solution:
    def maxSubArray(self, nums: List[int]) -> int:
        current_sum = nums[0]
        max_sum = nums[0]
        for num in nums[1:]:
            current_sum = max(num, current_sum + num)
            max_sum = max(max_sum, current_sum)
        return max_sum''',
        isAccepted: true,
        dateAdded: now.subtract(const Duration(days: 6)),
        lastSubmittedDate: null,
        submissionAttempts: 0,
        notes: "Kadane's algorithm O(n) time, O(1) space.",
      ),
      SavedProblem(
        leetCodeId: 704,
        title: 'Binary Search',
        slug: 'binary-search',
        url: 'https://leetcode.com/problems/binary-search/',
        difficulty: Difficulty.easy,
        language: 'Python 3',
        sourceCode: '''class Solution:
    def search(self, nums: List[int], target: int) -> int:
        left, right = 0, len(nums) - 1
        while left <= right:
            mid = left + (right - left) // 2
            if nums[mid] == target:
                return mid
            elif nums[mid] < target:
                left = mid + 1
            else:
                right = mid - 1
        return -1''',
        isAccepted: true,
        dateAdded: now.subtract(const Duration(days: 4)),
        lastSubmittedDate: null,
        submissionAttempts: 0,
        notes: 'Standard binary search template.',
      ),
      SavedProblem(
        leetCodeId: 226,
        title: 'Invert Binary Tree',
        slug: 'invert-binary-tree',
        url: 'https://leetcode.com/problems/invert-binary-tree/',
        difficulty: Difficulty.easy,
        language: 'Java',
        sourceCode: '''class Solution {
    public TreeNode invertTree(TreeNode root) {
        if (root == null) return null;
        TreeNode left = invertTree(root.left);
        TreeNode right = invertTree(root.right);
        root.left = right;
        root.right = left;
        return root;
    }
}''',
        isAccepted: true,
        dateAdded: now.subtract(const Duration(days: 2)),
        lastSubmittedDate: null,
        submissionAttempts: 0,
        notes: 'Recursive DFS tree inversion.',
      ),
    ];
  }
}

