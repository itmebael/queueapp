# Screen Script Explanation - Queue Management System

This document provides a comprehensive explanation of all screens in the Queue Management System, including their purpose, functionality, user flows, and key features.

---

## Table of Contents

1. [Welcome Screen](#1-welcome-screen)
2. [Queue Home Screen](#2-queue-home-screen)
3. [Information Form Screen](#3-information-form-screen)
4. [View Queue Screen](#4-view-queue-screen)
5. [Admin Login Screen](#5-admin-login-screen)
6. [Admin Screen](#6-admin-screen)
7. [Analytics Screen](#7-analytics-screen)
8. [CAS Analytics Screen](#8-cas-analytics-screen)
9. [Records View Screen](#9-records-view-screen)
10. [Department Management Screen](#10-department-management-screen)
11. [Purpose Management Screen](#11-purpose-management-screen)
12. [Course Management Screen](#12-course-management-screen)
13. [Bluetooth Device Screen](#13-bluetooth-device-screen)

---

## 1. Welcome Screen

**File:** `lib/screens/welcome_screen.dart`

### Purpose
The entry point of the application. Provides an animated welcome interface that introduces users to the Queue Management System.

### User Flow
1. App launches → Welcome Screen displays
2. User sees animated logo and welcome message
3. User taps "Get Started" button
4. Navigates to Queue Home Screen

### Key Features
- **Animated UI Elements:**
  - Fade-in animation for background
  - Slide-up animation for content
  - Scale animation for logo
  - Gradient background with queue image overlay

- **Visual Elements:**
  - Circular logo with border and shadow
  - Gradient text title: "Welcome to Registrar!"
  - Subtitle: "Queue Management System"
  - Prominent "Get Started" button with arrow icon

### Technical Details
- Uses `TickerProviderStateMixin` for animations
- Three animation controllers: fade, slide, and scale
- Smooth page transition to Queue Home Screen
- Material Design 3 styling

---

## 2. Queue Home Screen

**File:** `lib/screens/queue_home_screen.dart`

### Purpose
Main navigation hub for users. Provides access to queue entry, admin login, and queue viewing functionality.

### User Flow
1. User arrives from Welcome Screen
2. Sees three main options:
   - **Entry Queue**: Join the queue
   - **Admin**: Access admin panel
   - **View Queue**: See live queue display
3. Tapping "Entry Queue" shows dialog with two options:
   - **Request**: Create new queue ticket
   - **For Releasing**: Use reference number for document release
4. Based on selection, navigates to appropriate screen

### Key Features
- **Three Main Actions:**
  1. **Entry Queue Button:**
     - Opens entry type selection dialog
     - Two options: "Request" (new ticket) or "For Releasing" (reference lookup)
  
  2. **Admin Button:**
     - Navigates to Admin Login Screen
     - Requires authentication
  
  3. **View Queue Button:**
     - Navigates to View Queue Screen
     - Shows live queue display for all departments

- **Entry Type Dialog:**
  - **Request Option:**
    - Blue gradient card
    - Creates new queue entry
    - Navigates to Information Form Screen
  
  - **For Releasing Option:**
    - Green gradient card
    - Prompts for reference number
    - Searches existing queue entry
    - Creates new releasing queue entry
    - Generates ticket

- **Releasing Flow:**
  1. User enters reference number
  2. System searches for matching entry
  3. Displays confirmation dialog with entry details
  4. Creates new queue entry in "R" (Releasing) department
  5. Generates and prints ticket
  6. Shows success message with queue number

### Technical Details
- Staggered animations for buttons
- Animated logo display
- Page route transitions with slide animations
- Integration with Supabase for reference lookup
- Print service integration for ticket generation

---

## 3. Information Form Screen

**File:** `lib/screens/information_form_screen.dart`

### Purpose
Collects user information to create a new queue entry. Comprehensive form for capturing all necessary details including personal info, department, purpose, and priority status.

### User Flow
1. User navigates from Queue Home Screen (Request option)
2. Form displays with multiple sections:
   - Personal Information
   - Department Selection
   - Purpose Selection
   - Course Selection (if applicable)
   - Priority Queue Options
   - Additional Information
3. User fills out required fields
4. User submits form
5. System validates and creates queue entry
6. Success screen displays with queue number
7. Optional: Print ticket

### Key Features
- **Form Sections:**

  1. **Personal Information:**
     - Name (required)
     - SSU ID (required)
     - Email (required, validated)
     - Phone Number (required, auto-formatted with +63)

  2. **Department Selection:**
     - Dropdown with all active departments
     - CAS, COED, CONHS, COENG, CIT, CGS, R (Releasing)
     - Auto-populated from database

  3. **Purpose Selection:**
     - Dropdown with predefined purposes
     - "Others" option with custom text field
     - Custom purpose stored in notes field

  4. **Course Selection:**
     - Conditional display (shown for students)
     - Dropdown with courses filtered by department
     - Scrollable list for long course lists

  5. **Priority Queue Section:**
     - **PWD (Person with Disability)** checkbox
     - **Senior Citizen (60+)** checkbox
     - **Pregnant** checkbox
     - Visual feedback when priority options selected
     - Green-themed priority section

  6. **User Type Selection:**
     - Student
     - Graduated
     - External
     - Affects course selection visibility

  7. **Additional Information:**
     - Gender selection (optional)
     - Age input (optional)
     - Graduation Year (for graduated students)
     - Notes field (for custom purposes)

- **Validation:**
  - Required field validation
  - Email format validation
  - Phone number validation
  - Network connectivity check
  - Queue capacity check

- **Success Screen:**
  - Displays assigned queue number
  - Shows priority status if applicable
  - Option to print ticket
  - Confirmation of SMS/Email notifications
  - Button to return home

- **Notifications:**
  - SMS notification sent automatically
  - Email notification sent automatically
  - Bluetooth TTS announcement (if configured)

### Technical Details
- Form validation with `GlobalKey<FormState>`
- Animated form sections
- Dynamic course loading based on department
- Priority queue logic integration
- Supabase queue entry creation
- Print service integration
- Notification service integration

---

## 4. View Queue Screen

**File:** `lib/screens/view_queue_screen.dart`

### Purpose
Displays live queue information for all departments in a visual grid format. Shows current queue status, next in line, and countdown timers for active entries.

### User Flow
1. User navigates from Queue Home Screen
2. Screen loads all active departments
3. Displays queue grid for each department
4. Auto-refreshes every 2 seconds
5. Shows real-time updates via Supabase realtime subscriptions
6. Displays countdown timers for current entries

### Key Features
- **Department Grid Display:**
  - Each department shown in separate card
  - Fixed 4x3 grid (12 slots) per department
  - Shows top 12 active queue entries
  - Displays department name and total count

- **Queue Entry Display:**
  - **Queue Number**: Large, bold display
  - **SSU ID**: Below queue number
  - **Status Colors:**
    - Blue: Regular entries (waiting/current)
    - Green: Priority entries (PWD/Senior)
    - Red: Incomplete/missed entries
  - **Priority Icons:**
    - 🦽 PWD icon
    - 👴 Senior icon
    - 🦽 Combined PWD & Senior
    - 👶 Pregnant icon

- **Countdown Timer:**
  - Shows for current entry (status = 'current')
  - Visual progress bar
  - Color changes:
    - Blue: Normal time remaining
    - Orange: Less than 10 seconds
    - Red: Time expired
  - Displays remaining seconds

- **Real-Time Updates:**
  - Supabase realtime subscriptions
  - Auto-refresh every 2 seconds
  - Immediate updates on database changes
  - Department changes trigger reload

- **Bluetooth TTS Announcements:**
  - Automatic announcements when:
    - Entry status changes to 'current' (CALLING)
    - New person reaches top of queue (NEXT)
  - Department-specific Bluetooth devices
  - Fallback to local TTS if Bluetooth unavailable

- **Visual Features:**
  - Empty slots show "---" placeholder
  - First entry highlighted with thicker border
  - Staggered animations for department cards
  - Responsive grid layout

### Technical Details
- Real-time Supabase subscriptions
- Timer-based auto-refresh
- Bluetooth TTS service integration
- Department service integration
- Countdown timer calculations
- Status-based filtering (only waiting/current shown)

---

## 5. Admin Login Screen

**File:** `lib/screens/admin_login_screen.dart`

### Purpose
Authentication screen for administrators. Validates credentials and grants access to admin dashboard.

### User Flow
1. User navigates from Queue Home Screen (Admin button)
2. Login form displays
3. User enters username and password
4. User taps "Login" button
5. System validates credentials
6. On success: Navigate to Admin Screen
7. On failure: Show error message

### Key Features
- **Login Form:**
  - Username field (required)
  - Password field (required, obscured)
  - Show/hide password toggle
  - Form validation

- **Visual Design:**
  - Animated logo display
  - Gradient title: "Admin Login"
  - Subtitle: "Sign in to manage your department queue"
  - White card with shadow
  - Loading indicator during authentication

- **Authentication:**
  - Validates against AdminService
  - Supports department-specific admins
  - Master admin (department = 'ALL') support
  - Session management

- **Error Handling:**
  - Invalid credentials error
  - Network error handling
  - User-friendly error messages
  - Red snackbar for errors

### Technical Details
- Form validation
- AdminService integration
- Animated UI elements
- Page route transitions
- Session state management

---

## 6. Admin Screen

**File:** `lib/screens/admin_screen.dart`

### Purpose
Main dashboard for administrators. Provides comprehensive queue management, analytics access, and system configuration options.

### User Flow
1. Admin logs in successfully
2. Dashboard loads with department queue
3. Admin can:
   - View current queue
   - Manage queue entries (Start, Complete, Cancel, Incomplete)
   - Access analytics
   - Manage departments, purposes, courses
   - View records
   - Configure Bluetooth devices
   - Reset queue
4. Auto-refreshes every 5 seconds

### Key Features
- **Queue Management:**
  - **Current Person Display:**
    - Large queue number display
    - Person details (name, SSU ID, email, phone)
    - Priority status indicators
    - Countdown timer (if active)
    - Action buttons: Start, Complete, Cancel, Incomplete
  
  - **Queue List:**
    - Shows all waiting/current entries
    - Priority entries highlighted in green
    - Regular entries in blue
    - Sorted by priority, then queue number
    - Batch number display
  
  - **Queue Actions:**
    - **Start**: Begin serving current person (starts countdown)
    - **Complete**: Mark entry as done
    - **Cancel**: Cancel queue entry
    - **Incomplete**: Mark as incomplete (missed)
    - **Reset Queue**: Reset completed entries or entire queue

- **Dashboard Statistics:**
  - Total queue count
  - Waiting count
  - Current count
  - Completed count
  - Department-specific stats (for department admins)
  - All-department stats (for master admin)

- **Navigation Menu:**
  - **Analytics**: View analytics dashboard
  - **Records**: View all queue records
  - **Department Management**: Manage departments (master admin)
  - **Purpose Management**: Manage purposes
  - **Course Management**: Manage courses
  - **Bluetooth Devices**: Configure Bluetooth speakers
  - **Logout**: Sign out

- **Master Admin Features:**
  - View all departments
  - Department statistics overview
  - Purpose statistics by department/course
  - All queue entries access

- **Department Admin Features:**
  - View only their department
  - Department-specific statistics
  - Limited management options

- **Auto-Refresh:**
  - Silent refresh every 5 seconds
  - Checks for expired countdowns
  - Removes missed entries
  - Updates queue display

- **Queue Monitoring:**
  - Automatic notifications for top 5 in queue
  - SMS/Email reminders
  - Bluetooth announcements

### Technical Details
- Timer-based auto-refresh
- Queue monitoring service
- Bluetooth TTS integration
- Department service integration
- Supabase real-time updates
- Countdown timer management
- Priority queue sorting

---

## 7. Analytics Screen

**File:** `lib/screens/analytics_screen.dart`

### Purpose
Comprehensive analytics dashboard showing queue statistics, trends, and insights. Available to both master and department admins with appropriate data filtering.

### User Flow
1. Admin navigates from Admin Screen
2. Analytics dashboard loads
3. Admin can:
   - View overall statistics
   - Filter by department, course, purpose, date
   - View charts and graphs
   - Export data
4. Data refreshes automatically

### Key Features
- **Statistics Overview:**
  - Total entries
  - Completed entries
  - Waiting entries
  - Incomplete entries
  - Completion rate
  - Average wait time

- **Filtering Options:**
  - **Department Filter**: (Master admin only)
    - All departments
    - Specific department
  - **Course Filter**: Filter by course
  - **Purpose Filter**: Filter by purpose
  - **Date Filter**:
    - Month selector
    - Day selector
    - Date range

- **Charts and Visualizations:**
  - **Status Distribution Pie Chart:**
    - Waiting, Current, Done, Incomplete
    - Color-coded segments
    - Percentage labels
  
  - **Purpose Breakdown Chart:**
    - Bar chart or pie chart
    - Shows distribution by purpose
    - Count and percentage
  
  - **Time-Based Trends:**
    - Hourly distribution
    - Daily trends
    - Monthly trends
    - Line/bar charts
  
  - **Department Comparison:**
    - (Master admin only)
    - Side-by-side comparison
    - Statistics per department

- **Data Tables:**
  - Detailed entry list
  - Sortable columns
  - Search functionality
  - Pagination

- **Export Options:**
  - Excel export
  - CSV export
  - PDF report generation

- **Real-Time Updates:**
  - Auto-refresh capability
  - Manual refresh button
  - Live data from Supabase

### Technical Details
- AnalyticsService integration
- FL Chart library for visualizations
- Supabase query building with filters
- Department-based data filtering
- Date range calculations
- Excel export service integration

---

## 8. CAS Analytics Screen

**File:** `lib/screens/cas_analytics_screen.dart`

### Purpose
Specialized analytics screen specifically for CAS (College of Arts and Sciences) department. Provides department-specific insights and real-time monitoring.

### User Flow
1. Admin navigates to CAS Analytics (if applicable)
2. CAS-specific data loads
3. Real-time updates every 30 seconds
4. Displays CAS queue statistics and trends

### Key Features
- **CAS-Specific Data:**
  - CAS queue entries only
  - CAS statistics
  - CAS trends

- **Real-Time Monitoring:**
  - Updates every 30 seconds
  - Tracks real-time changes
  - Update history log

- **Visualizations:**
  - CAS-specific charts
  - Status distribution
  - Purpose breakdown
  - Time-based trends

### Technical Details
- Timer-based updates
- CAS department filtering
- Real-time update tracking
- Animated UI elements

---

## 9. Records View Screen

**File:** `lib/screens/records_view_screen.dart`

### Purpose
Comprehensive view of all queue records with advanced filtering, search, and export capabilities. Allows admins to review historical queue data.

### User Flow
1. Admin navigates from Admin Screen
2. Records load (filtered by admin's department)
3. Admin can:
   - Filter by status, priority, purpose
   - Search by name, SSU ID, reference number
   - Filter by date range
   - View latest batch only
   - Export to Excel
4. Records display in sortable table

### Key Features
- **Record Display:**
  - List/table view of all records
  - Sortable columns
  - Pagination for large datasets
  - Detailed entry information

- **Filtering Options:**
  - **Status Filter:**
    - All
    - Waiting
    - Current
    - Done
    - Incomplete
    - Cancelled
  
  - **Priority Filter:**
    - All
    - Priority
    - PWD
    - Senior
    - Pregnant
    - Regular
  
  - **Purpose Filter:**
    - All purposes
    - Specific purpose
  
  - **Date Range Filter:**
    - Start date picker
    - End date picker
    - Latest batch toggle

- **Search Functionality:**
  - Search by name
  - Search by SSU ID
  - Search by reference number
  - Real-time search filtering

- **Statistics Display:**
  - Total records count
  - Status distribution
  - Priority distribution
  - Purpose distribution
  - Date range summary

- **Export Features:**
  - Export filtered records to Excel
  - Export all records
  - Custom export options
  - Progress indicator during export

- **Record Details:**
  - Full entry information
  - Timestamp
  - Department
  - Purpose
  - Priority status
  - Course (if applicable)
  - Notes

### Technical Details
- Supabase query with multiple filters
- Excel export service integration
- Search text controller
- Date range filtering
- Batch number tracking
- Department-based filtering for non-master admins

---

## 10. Department Management Screen

**File:** `lib/screens/department_management_screen.dart`

### Purpose
Allows master administrators to manage departments: create, edit, activate/deactivate, and view department statistics.

### User Flow
1. Master admin navigates from Admin Screen
2. Department list loads with statistics
3. Admin can:
   - View all departments
   - Add new department
   - Edit existing department
   - Activate/deactivate department
   - View department statistics
   - Navigate to course management for department

### Key Features
- **Department List:**
  - All departments displayed
  - Department code and name
  - Active/inactive status indicator
  - Statistics per department:
    - Waiting count
    - Current count
    - Completed count
    - Incomplete count
    - Total count

- **Department Actions:**
  - **Add Department:**
    - Code input (unique)
    - Name input
    - Description input
    - Active status toggle
  
  - **Edit Department:**
    - Modify name
    - Modify description
    - Toggle active status
  
  - **Delete/Deactivate:**
    - Soft delete (deactivate)
    - Confirmation dialog
    - Prevents deletion if has queue entries

- **Statistics Display:**
  - Real-time department statistics
  - Queue counts per department
  - Status distribution
  - Auto-refresh every 30 seconds

- **Navigation:**
  - Link to Course Management for department
  - Filter courses by department

### Technical Details
- DepartmentService integration
- Supabase department operations
- Statistics calculation
- Active/inactive status management
- Validation for department codes

---

## 11. Purpose Management Screen

**File:** `lib/screens/purpose_management_screen.dart`

### Purpose
Allows administrators to manage queue purposes: create, edit, and delete purposes that users can select when joining the queue.

### User Flow
1. Admin navigates from Admin Screen
2. Purpose list loads
3. Admin can:
   - View all purposes
   - Add new purpose
   - Edit existing purpose
   - Delete purpose
4. Changes reflect in Information Form Screen

### Key Features
- **Purpose List:**
  - All purposes displayed
  - Purpose name and description
  - Creation timestamp
  - Usage count (if available)

- **Purpose Actions:**
  - **Add Purpose:**
    - Name input (uppercase, unique)
    - Description input
    - Validation
  
  - **Edit Purpose:**
    - Modify name
    - Modify description
    - Update timestamp
  
  - **Delete Purpose:**
    - Confirmation dialog
    - Prevents deletion if in use

- **Validation:**
  - Unique purpose names
  - Required fields
  - Name format validation

### Technical Details
- PurposeService integration
- Supabase purpose operations
- Form validation
- Success/error notifications

---

## 12. Course Management Screen

**File:** `lib/screens/course_management_screen.dart`

### Purpose
Allows administrators to manage courses: create, edit, and delete courses. Courses are associated with departments and used in queue entries.

### User Flow
1. Admin navigates from Admin Screen or Department Management
2. Course list loads (optionally filtered by department)
3. Admin can:
   - View all courses or department-specific courses
   - Add new course
   - Edit existing course
   - Delete course
4. Changes reflect in Information Form Screen

### Key Features
- **Course List:**
  - All courses or filtered by department
  - Course code and name
  - Department association
  - Description

- **Course Actions:**
  - **Add Course:**
    - Code input
    - Name input
    - Description input
    - Department selection
    - Validation
  
  - **Edit Course:**
    - Modify code
    - Modify name
    - Modify description
    - Change department
  
  - **Delete Course:**
    - Confirmation dialog
    - Prevents deletion if in use

- **Department Filtering:**
  - View all courses
  - Filter by specific department
  - Department dropdown selector

- **Validation:**
  - Unique course codes
  - Required fields
  - Department validation

### Technical Details
- CourseService integration
- DepartmentService integration
- Supabase course operations
- Form validation
- Department-based filtering

---

## 13. Bluetooth Device Screen

**File:** `lib/screens/bluetooth_device_screen.dart`

### Purpose
Allows administrators to configure Bluetooth speakers for queue announcements. Connects Bluetooth devices to specific departments for audio announcements.

### User Flow
1. Admin navigates from Admin Screen
2. Bluetooth Device Screen opens for selected department
3. Admin can:
   - Check Bluetooth status
   - Scan for available devices
   - Connect to Bluetooth speaker
   - Disconnect device
   - Test connection
4. Connected device used for TTS announcements

### Key Features
- **Bluetooth Status:**
  - Bluetooth enabled/disabled indicator
  - Bluetooth supported check
  - Current connection status
  - Enable Bluetooth button (if disabled)

- **Device Scanning:**
  - Scan for available devices
  - List of discovered devices
  - Device name and MAC address
  - Signal strength indicator
  - Stop scan button

- **Device Connection:**
  - Connect to selected device
  - Connection status indicator
  - Connected device display
  - Disconnect button
  - Connection error handling

- **Device Management:**
  - Save connected device for department
  - Load previously connected device
  - Test announcement button
  - Device information display

- **Department Association:**
  - Each department can have one Bluetooth device
  - Device saved per department
  - Automatic device selection for announcements

### Technical Details
- Flutter Blue Plus integration
- Bluetooth adapter state monitoring
- Device scanning and connection
- SharedPreferences for device storage
- BluetoothTtsService integration
- Platform-specific Bluetooth support

---

## Screen Navigation Flow

```
Welcome Screen
    ↓
Queue Home Screen
    ├── Entry Queue → Information Form Screen → Success Screen
    ├── Admin → Admin Login Screen → Admin Screen
    │              ├── Analytics Screen
    │              ├── Records View Screen
    │              ├── Department Management Screen
    │              ├── Purpose Management Screen
    │              ├── Course Management Screen
    │              └── Bluetooth Device Screen
    └── View Queue Screen
```

---

## Common Features Across Screens

### Animations
- Most screens use fade, slide, and scale animations
- Smooth page transitions
- Staggered animations for lists
- Loading indicators

### Error Handling
- Network error detection
- User-friendly error messages
- Snackbar notifications
- Graceful degradation

### Data Loading
- Loading indicators
- Async data fetching
- Error states
- Empty states

### Responsive Design
- Material Design 3
- Consistent color scheme (Color(0xFF263277))
- Gradient accents
- Card-based layouts

---

## Technical Stack

- **Framework**: Flutter 3.0+
- **Backend**: Supabase
- **State Management**: StatefulWidget with setState
- **Animations**: AnimationController, Tween, CurvedAnimation
- **Charts**: FL Chart library
- **Bluetooth**: Flutter Blue Plus
- **Printing**: Printing package (when available)
- **Excel**: Excel package

---

*Last Updated: 2024*
*System Version: 1.0.0+1*

