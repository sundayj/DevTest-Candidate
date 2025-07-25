# Task 6: Bug Hunt & Debugging Challenge

**Time Allocation**: 1-2 hours  
**Difficulty Level**: All Levels (Adjustable)  
**Focus Areas**: Debugging, Problem-Solving, Code Analysis

## Overview

Find and fix intentionally introduced bugs in the DevTest book catalog system. This task evaluates your debugging methodology, problem identification skills, and ability to systematically troubleshoot issues. The bugs range from simple syntax errors to complex logic problems and performance issues.

## Project Setup

Follow the [Running the Project guide](../setup/running-project.md) to start the application with DevContainer, Docker Compose, or GitHub Codespaces.

## Task Requirements

### Bug Categories

#### 1. **Model & Database Issues** (Required)
- Incorrect model relationships
- Missing database constraints
- Query optimization problems
- Data integrity issues

#### 2. **View & Logic Bugs** (Required)
- Incorrect business logic
- Missing error handling
- Authentication/permission issues
- Form validation problems

#### 3. **Template & Frontend Issues** (Required)
- Template rendering errors
- JavaScript functionality bugs
- CSS styling problems
- Responsive design issues

#### 4. **Performance Problems** (Optional)
- N+1 query issues
- Inefficient algorithms
- Memory leaks
- Slow database queries

#### 5. **Security Vulnerabilities** (Optional)
- SQL injection risks
- XSS vulnerabilities
- CSRF token issues
- Authentication bypasses

## Bug Scenarios

### Scenario 1: Model Relationship Bug

**Symptom**: Authors with no books still appear in the top authors list

**Location**: `devtest/app/models.py`

**Bug**: The `top_authors` method doesn't filter out authors without books

```python
# BUGGY CODE (for reference - don't include in actual task)
def top_authors(self, limit=5):
    """Return the top authors ordered by average rating."""
    return (
        self.with_average_rating()
        .order_by(models.F("avg_rating").desc(nulls_last=True))[:limit]
    )

# EXPECTED FIX
def top_authors(self, limit=5):
    """Return the top authors ordered by average rating."""
    return (
        self.with_average_rating()
        .filter(book_count__gt=0)  # Only authors with books
        .order_by(models.F("avg_rating").desc(nulls_last=True))[:limit]
    )
```

### Scenario 2: View Logic Bug

**Symptom**: Users can submit multiple reviews for the same book

**Location**: `devtest/app/views.py`

**Bug**: Missing uniqueness check in review submission

```python
# BUGGY CODE
def add_review(request, book_id):
    if request.method == 'POST':
        form = ReviewForm(request.POST)
        if form.is_valid():
            review = form.save(commit=False)
            review.book_id = book_id
            review.user = request.user
            review.save()  # No check for existing review
            return redirect('book_detail', pk=book_id)

# EXPECTED FIX
def add_review(request, book_id):
    if request.method == 'POST':
        # Check if user already reviewed this book
        existing_review = Review.objects.filter(
            book_id=book_id, 
            user=request.user
        ).first()
        
        if existing_review:
            messages.error(request, 'You have already reviewed this book.')
            return redirect('book_detail', pk=book_id)
        
        form = ReviewForm(request.POST)
        if form.is_valid():
            review = form.save(commit=False)
            review.book_id = book_id
            review.user = request.user
            review.save()
            return redirect('book_detail', pk=book_id)
```

### Scenario 3: Template Bug

**Symptom**: Book ratings display as numbers instead of stars

**Location**: `devtest/app/templates/app/book_detail.html`

**Bug**: Missing template filter or incorrect variable usage

```html
<!-- BUGGY CODE -->
<div class="rating">
    Rating: {{ book.average_rating }}
</div>

<!-- EXPECTED FIX -->
<div class="rating">
    Rating: 
    {% for i in "12345" %}
        {% if forloop.counter <= book.average_rating %}
            <span class="star filled">★</span>
        {% else %}
            <span class="star">☆</span>
        {% endif %}
    {% endfor %}
    ({{ book.average_rating }})
</div>
```

### Scenario 4: JavaScript Bug

**Symptom**: Search functionality doesn't work

**Location**: `devtest/app/static/js/search.js`

**Bug**: Incorrect event binding or AJAX call

```javascript
// BUGGY CODE
$(document).ready(function() {
    $('#search-form').submit(function(e) {
        e.preventDefault();
        var query = $('#search-input').val();
        
        $.ajax({
            url: '/search/',  // Wrong URL
            method: 'GET',
            data: {'q': query},
            success: function(data) {
                $('#results').html(data);
            }
        });
    });
});

// EXPECTED FIX
$(document).ready(function() {
    $('#search-form').submit(function(e) {
        e.preventDefault();
        var query = $('#search-input').val();
        
        $.ajax({
            url: '/api/books/search/',  // Correct URL
            method: 'GET',
            data: {'search': query},  // Correct parameter name
            success: function(data) {
                $('#results').html(data);
            },
            error: function(xhr, status, error) {
                console.error('Search failed:', error);
            }
        });
    });
});
```

### Scenario 5: Performance Bug

**Symptom**: Book list page loads very slowly

**Location**: `devtest/app/views.py`

**Bug**: N+1 query problem in book listing

```python
# BUGGY CODE
def book_list(request):
    books = Book.objects.all()  # N+1 queries when accessing author/genres
    return render(request, 'app/book_list.html', {'books': books})

# EXPECTED FIX
def book_list(request):
    books = Book.objects.select_related('author').prefetch_related('genres', 'review_set')
    return render(request, 'app/book_list.html', {'books': books})
```

### Scenario 6: Security Bug

**Symptom**: Users can delete any review, not just their own

**Location**: `devtest/app/views.py`

**Bug**: Missing permission check

```python
# BUGGY CODE
def delete_review(request, review_id):
    review = get_object_or_404(Review, id=review_id)
    review.delete()  # No ownership check
    return redirect('book_detail', pk=review.book.id)

# EXPECTED FIX
def delete_review(request, review_id):
    review = get_object_or_404(Review, id=review_id)
    
    # Check if user owns the review or is staff
    if review.user != request.user and not request.user.is_staff:
        raise PermissionDenied("You can only delete your own reviews.")
    
    book_id = review.book.id
    review.delete()
    return redirect('book_detail', pk=book_id)
```

## Debugging Methodology

### 1. **Systematic Approach**
1. **Reproduce the Issue**: Understand the exact steps to trigger the bug
2. **Gather Information**: Check logs, error messages, and stack traces
3. **Isolate the Problem**: Narrow down the scope to specific components
4. **Form Hypotheses**: Make educated guesses about the root cause
5. **Test Solutions**: Implement fixes and verify they work
6. **Document Changes**: Record what was changed and why

### 2. **Debugging Tools**

#### Django Debug Toolbar
```python
# Add to settings.py for debugging
if DEBUG:
    INSTALLED_APPS += ['debug_toolbar']
    MIDDLEWARE += ['debug_toolbar.middleware.DebugToolbarMiddleware']
    INTERNAL_IPS = ['127.0.0.1']
```

#### Logging Configuration
```python
# settings.py
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django.db.backends': {
            'handlers': ['console'],
            'level': 'DEBUG',
        },
    },
}
```

#### Browser Developer Tools
- Console for JavaScript errors
- Network tab for AJAX requests
- Elements tab for HTML/CSS issues

### 3. **Common Debugging Techniques**

#### Print/Log Debugging
```python
import logging
logger = logging.getLogger(__name__)

def problematic_function():
    logger.debug(f"Function called with args: {args}")
    # ... rest of function
```

#### Django Shell Investigation
```python
# python manage.py shell
from devtest.app.models import Book, Author, Review

# Test queries
books = Book.objects.all()
print(f"Total books: {books.count()}")

# Check for data issues
authors_without_books = Author.objects.filter(book__isnull=True)
print(f"Authors without books: {authors_without_books.count()}")
```

#### Database Query Analysis
```python
from django.db import connection

# Reset query log
connection.queries_log.clear()

# Run problematic code
books = Book.objects.all()
for book in books:
    print(book.author.name)  # This might cause N+1 queries

# Check queries
print(f"Number of queries: {len(connection.queries)}")
for query in connection.queries:
    print(query['sql'])
```

## Bug Documentation Template

For each bug found, document using this template:

```markdown
## Bug #X: [Brief Description]

### Symptoms
- What the user experiences
- Error messages (if any)
- Steps to reproduce

### Root Cause
- Technical explanation of the problem
- Why it occurs

### Location
- File path and line numbers
- Affected components

### Solution
- Code changes made
- Explanation of the fix

### Testing
- How to verify the fix works
- Edge cases considered

### Prevention
- How to avoid similar bugs in the future
- Code review points
```

## Evaluation Criteria

### Problem Identification (25%)
- Speed of bug discovery
- Accuracy in identifying root causes
- Understanding of symptoms vs. causes
- Systematic debugging approach

### Solution Quality (25%)
- Correctness of fixes
- Code quality of solutions
- Consideration of edge cases
- Prevention of regression

### Debugging Process (20%)
- Methodical approach
- Use of appropriate tools
- Documentation of findings
- Communication of issues

### Technical Knowledge (15%)
- Understanding of Django framework
- Database query optimization
- Frontend debugging skills
- Security awareness

### Time Management (15%)
- Efficient use of debugging time
- Prioritization of critical bugs
- Balance between speed and thoroughness
- Ability to work under pressure

## Tools and Resources

### Debugging Tools
- **Django Debug Toolbar**: Query analysis and performance profiling
- **Browser DevTools**: Frontend debugging and network analysis
- **Python Debugger (pdb)**: Step-through debugging
- **Django Shell**: Interactive model and query testing
- **Logging**: Systematic error tracking

### Useful Commands
```bash
# Check for common issues
python manage.py check
python manage.py check --deploy

# Database inspection
python manage.py dbshell
python manage.py showmigrations

# Testing
python manage.py test --debug-mode
python manage.py test --keepdb

# Performance analysis
python manage.py shell
>>> from django.test.utils import override_settings
>>> with override_settings(DEBUG=True):
...     # Run problematic code
```

## Submission Guidelines

### What to Submit
1. **Bug Report**: Detailed documentation of each bug found
2. **Fixed Code**: All corrected files with clear comments
3. **Test Cases**: Tests that verify fixes work correctly
4. **Process Documentation**: Your debugging methodology
5. **Prevention Recommendations**: Suggestions to avoid similar issues

### Bug Report Format
```
Bug ID: BUG-001
Title: Users can submit multiple reviews for same book
Severity: Medium
Status: Fixed

Description:
The system allows users to submit multiple reviews for the same book,
which violates business logic and can skew ratings.

Steps to Reproduce:
1. Login as a user
2. Navigate to any book detail page
3. Submit a review
4. Submit another review for the same book
5. Both reviews are saved

Expected Behavior:
Users should only be able to submit one review per book.

Actual Behavior:
Multiple reviews are accepted and saved.

Root Cause:
Missing uniqueness check in the add_review view function.

Solution:
Added validation to check for existing reviews before saving new ones.

Files Changed:
- devtest/app/views.py (lines 45-52)
- devtest/app/models.py (added unique constraint)

Testing:
- Manual testing confirmed fix works
- Added unit test test_duplicate_review_prevention()
```

## Time Management Tips

### For 1-Hour Session
- **15 minutes**: Quick scan for obvious bugs
- **30 minutes**: Focus on 2-3 critical issues
- **15 minutes**: Document findings and fixes

### For 2-Hour Session
- **30 minutes**: Systematic bug hunting across all components
- **60 minutes**: Fix identified bugs with proper testing
- **30 minutes**: Documentation and prevention recommendations

## Common Pitfalls to Avoid

- **Fixing symptoms instead of root causes**
- **Not testing fixes thoroughly**
- **Making changes without understanding the impact**
- **Poor documentation of changes**
- **Not considering edge cases**
- **Rushing through without proper analysis**
- **Not using available debugging tools**

## Success Indicators

- **Systematic Approach**: Following a methodical debugging process
- **Tool Proficiency**: Effective use of debugging tools
- **Root Cause Analysis**: Identifying underlying issues, not just symptoms
- **Quality Fixes**: Solutions that are robust and well-tested
- **Clear Communication**: Good documentation of problems and solutions
- **Prevention Mindset**: Thinking about how to avoid similar issues

Good luck with your bug hunting! Remember that debugging is as much about the process as it is about the final solution. Focus on being systematic, thorough, and clear in your documentation.
