# Task 6: Bug Hunt & Debugging Challenge

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

## Debugging Methodology

### Systematic Approach
1. **Reproduce the Issue**
   - Identify the exact steps to trigger the bug
   - Document the expected vs actual behavior
   - Note any error messages or symptoms

2. **Analyze the Code**
   - Review relevant models, views, and templates
   - Check for logical errors and edge cases
   - Examine database queries and relationships

3. **Use Debugging Tools**
   - Django debug toolbar
   - Python debugger (pdb)
   - Browser developer tools
   - Database query analysis

4. **Test Your Fixes**
   - Verify the bug is resolved
   - Ensure no new issues are introduced
   - Test edge cases and related functionality

## Submission Guidelines

### What to Submit
1. List of bugs found with descriptions
2. Root cause analysis for each bug
3. Code fixes with explanations
4. Test cases to prevent regression
5. Documentation of debugging process used

### Code Organization
- Make minimal, targeted fixes
- Use meaningful commit messages for each bug fix
- Include comments explaining complex fixes
- Ensure fixes don't break existing functionality

### Testing Your Solution
Before submission, verify:
- All identified bugs are fixed
- Application functions correctly
- No new bugs were introduced
- Performance hasn't degraded
- Security issues are resolved

## Helpful Resources

- **Django Debugging**: https://docs.djangoproject.com/en/stable/topics/logging/
- **Python Debugger**: https://docs.python.org/3/library/pdb.html
- **Django Debug Toolbar**: https://django-debug-toolbar.readthedocs.io/
- **Browser DevTools**: https://developer.mozilla.org/en-US/docs/Tools

Good luck with your debugging! Focus on systematic problem-solving and thorough testing of your fixes.
