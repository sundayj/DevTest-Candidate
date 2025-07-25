# Task 3: User Authentication & Authorization System

**Time Allocation**: 2-3 hours  
**Difficulty Level**: Mid-Level  
**Focus Areas**: Authentication, Authorization, User Management, Security

## Overview

Implement a comprehensive user authentication and authorization system for the DevTest book catalog. This task evaluates your understanding of Django's authentication framework, user management, role-based permissions, and security best practices.

## Project Setup

Follow the [Running the Project guide](../setup/running-project.md) to start the application with DevContainer, Docker Compose, or GitHub Codespaces.

## Task Requirements

### Core Authentication Features (Required)

1. **User Registration & Login**
   - User registration form with validation
   - Login/logout functionality
   - Password strength validation
   - Email verification (optional but recommended)
   - Remember me functionality

2. **Password Management**
   - Password reset via email
   - Change password for logged-in users
   - Password history (prevent reusing recent passwords)
   - Account lockout after failed attempts

3. **User Profiles**
   - User profile page with editable information
   - Profile picture upload
   - User preferences and settings
   - Account deactivation option

4. **Role-Based Authorization**
   - **Regular User**: Can view books, add reviews
   - **Reviewer**: Can moderate reviews, access review analytics
   - **Admin**: Full access to all features
   - **Staff**: Can manage books and authors

### Advanced Features (Optional)

- Two-factor authentication (2FA)
- OAuth integration (Google, GitHub)
- Social login functionality
- User activity tracking
- Session management
- API token management

## Implementation Guidelines

### 1. User Model Extension

Extend Django's User model or create a custom user model:

```python
# models.py
from django.contrib.auth.models import AbstractUser, Group, Permission
from django.db import models

class CustomUser(AbstractUser):
    email = models.EmailField(unique=True)
    profile_picture = models.ImageField(upload_to='profiles/', blank=True)
    bio = models.TextField(max_length=500, blank=True)
    birth_date = models.DateField(null=True, blank=True)
    email_verified = models.BooleanField(default=False)
    failed_login_attempts = models.IntegerField(default=0)
    account_locked_until = models.DateTimeField(null=True, blank=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

class UserProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE)
    favorite_genres = models.ManyToManyField('Genre', blank=True)
    reading_list = models.ManyToManyField('Book', blank=True)
    notification_preferences = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

### 2. Authentication Forms

Create comprehensive forms for user authentication:

```python
# forms.py
from django import forms
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth.password_validation import validate_password
from .models import CustomUser

class CustomUserCreationForm(UserCreationForm):
    email = forms.EmailField(required=True)
    first_name = forms.CharField(max_length=30, required=True)
    last_name = forms.CharField(max_length=30, required=True)
    
    class Meta:
        model = CustomUser
        fields = ('username', 'email', 'first_name', 'last_name', 'password1', 'password2')
    
    def clean_email(self):
        email = self.cleaned_data.get('email')
        if CustomUser.objects.filter(email=email).exists():
            raise forms.ValidationError("Email already exists")
        return email

class CustomAuthenticationForm(AuthenticationForm):
    remember_me = forms.BooleanField(required=False)
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['username'].widget.attrs.update({'class': 'form-control'})
        self.fields['password'].widget.attrs.update({'class': 'form-control'})

class ProfileUpdateForm(forms.ModelForm):
    class Meta:
        model = CustomUser
        fields = ['first_name', 'last_name', 'email', 'bio', 'profile_picture']
        widgets = {
            'bio': forms.Textarea(attrs={'rows': 4}),
        }
```

### 3. Views Implementation

```python
# views.py
from django.shortcuts import render, redirect
from django.contrib.auth import login, authenticate
from django.contrib.auth.decorators import login_required
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.views.generic import CreateView, UpdateView
from django.urls import reverse_lazy

class SignUpView(CreateView):
    form_class = CustomUserCreationForm
    template_name = 'registration/signup.html'
    success_url = reverse_lazy('login')
    
    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(self.request, 'Account created successfully!')
        return response

class ProfileView(LoginRequiredMixin, UpdateView):
    model = CustomUser
    form_class = ProfileUpdateForm
    template_name = 'accounts/profile.html'
    success_url = reverse_lazy('profile')
    
    def get_object(self):
        return self.request.user

@login_required
def dashboard(request):
    user = request.user
    context = {
        'user': user,
        'recent_reviews': user.review_set.all()[:5] if hasattr(user, 'review_set') else [],
        'favorite_books': user.userprofile.reading_list.all()[:5] if hasattr(user, 'userprofile') else [],
    }
    return render(request, 'accounts/dashboard.html', context)
```

### 4. Permission System

Implement role-based permissions:

```python
# permissions.py
from django.contrib.auth.models import Group, Permission
from django.contrib.contenttypes.models import ContentType
from .models import Book, Review, Author

def create_user_groups():
    # Create groups
    reviewer_group, created = Group.objects.get_or_create(name='Reviewers')
    admin_group, created = Group.objects.get_or_create(name='Admins')
    staff_group, created = Group.objects.get_or_create(name='Staff')
    
    # Get content types
    book_ct = ContentType.objects.get_for_model(Book)
    review_ct = ContentType.objects.get_for_model(Review)
    author_ct = ContentType.objects.get_for_model(Author)
    
    # Reviewer permissions
    reviewer_permissions = [
        Permission.objects.get(codename='add_review', content_type=review_ct),
        Permission.objects.get(codename='change_review', content_type=review_ct),
        Permission.objects.get(codename='delete_review', content_type=review_ct),
    ]
    reviewer_group.permissions.set(reviewer_permissions)
    
    # Staff permissions
    staff_permissions = reviewer_permissions + [
        Permission.objects.get(codename='add_book', content_type=book_ct),
        Permission.objects.get(codename='change_book', content_type=book_ct),
        Permission.objects.get(codename='add_author', content_type=author_ct),
        Permission.objects.get(codename='change_author', content_type=author_ct),
    ]
    staff_group.permissions.set(staff_permissions)

# Custom decorators
from functools import wraps
from django.core.exceptions import PermissionDenied

def role_required(role):
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            if not request.user.is_authenticated:
                raise PermissionDenied
            if not request.user.groups.filter(name=role).exists():
                raise PermissionDenied
            return view_func(request, *args, **kwargs)
        return _wrapped_view
    return decorator
```

### 5. Templates Structure

```
templates/
├── registration/
│   ├── login.html
│   ├── signup.html
│   ├── password_reset_form.html
│   ├── password_reset_done.html
│   ├── password_reset_confirm.html
│   └── password_reset_complete.html
├── accounts/
│   ├── profile.html
│   ├── dashboard.html
│   ├── settings.html
│   └── components/
│       ├── user_menu.html
│       └── profile_sidebar.html
```

### 6. URL Configuration

```python
# urls.py
from django.urls import path, include
from django.contrib.auth import views as auth_views
from . import views

urlpatterns = [
    # Authentication URLs
    path('signup/', views.SignUpView.as_view(), name='signup'),
    path('login/', auth_views.LoginView.as_view(), name='login'),
    path('logout/', auth_views.LogoutView.as_view(), name='logout'),
    
    # Password reset URLs
    path('password-reset/', auth_views.PasswordResetView.as_view(), name='password_reset'),
    path('password-reset/done/', auth_views.PasswordResetDoneView.as_view(), name='password_reset_done'),
    path('reset/<uidb64>/<token>/', auth_views.PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    path('reset/done/', auth_views.PasswordResetCompleteView.as_view(), name='password_reset_complete'),
    
    # Profile URLs
    path('profile/', views.ProfileView.as_view(), name='profile'),
    path('dashboard/', views.dashboard, name='dashboard'),
    
    # Settings
    path('settings/', views.user_settings, name='user_settings'),
]
```

## Security Considerations

### 1. Password Security
```python
# settings.py
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
        'OPTIONS': {'min_length': 8,}
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Session security
SESSION_COOKIE_SECURE = True  # HTTPS only
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_AGE = 3600  # 1 hour
SESSION_EXPIRE_AT_BROWSER_CLOSE = True
```

### 2. Account Lockout Implementation
```python
# utils.py
from django.utils import timezone
from datetime import timedelta

def handle_failed_login(user):
    user.failed_login_attempts += 1
    if user.failed_login_attempts >= 5:
        user.account_locked_until = timezone.now() + timedelta(minutes=30)
    user.save()

def is_account_locked(user):
    if user.account_locked_until:
        if timezone.now() < user.account_locked_until:
            return True
        else:
            # Unlock account
            user.account_locked_until = None
            user.failed_login_attempts = 0
            user.save()
    return False
```

## Evaluation Criteria

### Authentication Implementation (25%)
- Proper user registration and login
- Password validation and security
- Session management
- Form validation and error handling

### Authorization & Permissions (25%)
- Role-based access control
- Permission decorators and mixins
- Group management
- Security enforcement

### User Experience (20%)
- Intuitive interface design
- Clear feedback messages
- Responsive forms
- Navigation and flow

### Security Best Practices (20%)
- Password security
- CSRF protection
- Input validation
- Account lockout mechanisms

### Code Quality (10%)
- Clean, readable code
- Proper error handling
- DRY principles
- Documentation

## Testing Your Implementation

### Manual Testing Checklist
- [ ] User can register with valid information
- [ ] Registration fails with invalid data
- [ ] User can login with correct credentials
- [ ] Login fails with incorrect credentials
- [ ] Password reset email is sent
- [ ] Password reset link works correctly
- [ ] User profile can be updated
- [ ] Role-based permissions work correctly
- [ ] Account lockout works after failed attempts
- [ ] Sessions expire correctly

### Security Testing
- [ ] SQL injection protection
- [ ] XSS protection
- [ ] CSRF token validation
- [ ] Password strength enforcement
- [ ] Session hijacking protection

## Submission Guidelines

### What to Submit
1. User model extensions
2. Authentication forms
3. View implementations
4. Template files
5. URL configurations
6. Permission system
7. Security configurations
8. Documentation of your approach

### Code Organization
```
accounts/
├── models.py
├── forms.py
├── views.py
├── permissions.py
├── utils.py
├── urls.py
└── templates/
```

## Helpful Resources

- **Django Authentication**: https://docs.djangoproject.com/en/stable/topics/auth/
- **Django Permissions**: https://docs.djangoproject.com/en/stable/topics/auth/default/#permissions-and-authorization
- **Security Best Practices**: https://docs.djangoproject.com/en/stable/topics/security/
- **Password Validation**: https://docs.djangoproject.com/en/stable/topics/auth/passwords/

## Time Management Tips

- **Hour 1**: Set up user model, basic forms, and views
- **Hour 2**: Implement authentication flows and templates
- **Hour 3**: Add role-based permissions and security features

## Common Pitfalls to Avoid

- Not validating user input properly
- Missing CSRF protection
- Weak password requirements
- Not implementing account lockout
- Storing passwords in plain text
- Not handling edge cases in authentication
- Missing proper error messages
- Not testing permission enforcement

Good luck implementing your authentication system! Focus on security, user experience, and proper Django patterns.
