# Career Counsellor App - System Architecture & Route Context

This document provides a comprehensive overview of the system architecture, routing, and database connectivity for both the Web Frontend (React) and Mobile App (Flutter), sharing a unified FastAPI Backend.

## 1. System Architecture
- **Web Frontend**: React (Vite), Tailwind CSS, Framer Motion.
- **Mobile Frontend**: Flutter (Dart).
- **Backend**: FastAPI (Python), SQLAlchemy (ORM).
- **Database**: PostgreSQL.
- **Authentication**: JWT (JSON Web Tokens) with Role-Based Access Control (Student, Mentor, Parent).

---

## 2. User Roles & Core Features
### A. Student
1. **Profile Creation**: Basic details and initial interests.
2. **Assessment Suite**:
   - **Personality Test**: Big Five/OCEAN model.
   - **Aptitude Test**: Grade-specific (6-8, 9-12) measuring Quantitative, Logical, Verbal.
   - **Psychometric Modules**: Emotional Quotient (EQ), Orientation Style, Career Interests (1-5 Likert scale).
3. **Discovery Report**: Unified results from all assessments.
4. **Career Recommendations**: AI-driven suggestions based on profile + assessments.
5. **Roadmap**: Dynamic learning path for chosen careers.
6. **Mentorship**: Connect with verified mentors for guidance.

### B. Mentor
1. **Dashboard**: Manage connections and requests.
2. **Chat & Video**: Direct interaction with students.
3. **Profile Management**: Set expertise and career goal alignment.

### C. Parent
1. **Student Linking**: Connect via unique invite codes.
2. **Progress Monitoring**: View ward's assessment reports and roadmap progress.

---

## 3. API Route Map (v1)

### Auth & User (`api/v1/auth`)
- `POST /login`: Get JWT token.
- `POST /register`: Create new account.
- `GET /users/me`: Fetch current user profile + progress.
- `GET /users/invite-code`: (Student) Get code for parents.

### Assessments (`api/v1/assessments` & `api/v1/psychometrics`)
- `GET /assessments/questions/{module}`: Fetch questions (Personality, Aptitude, Basic).
- `GET /assessments/aptitude/generate/assessment-pool`: Specialized aptitude fetch with grade logic.
- `POST /assessments/submit-generic`: Submit results for Personality/Aptitude.
- `GET /psychometrics/{module}/questions`: Fetch Likert questions (EQ, Orientation, Interest).
- `POST /psychometrics/{module}/score`: Submit 1-5 scores.
- `PATCH /assessments/save-progress`: Mid-test state saving.

### Careers & AI (`api/v1/ai` & `api/v1/career`)
- `POST /ai/recommend`: Generate career suggestions.
- `POST /ai/select-career`: Confirm a career choice.
- `GET /career/search`: Manual career database search.

### Roadmaps (`api/v1/roadmaps`)
- `GET /roadmaps/generate`: Create AI roadmap for a specific career.
- `POST /roadmaps/save`: Persist the generated roadmap.
- `GET /roadmaps/current`: Fetch the active roadmap for the student.
- `PATCH /roadmaps/tasks/{task_id}/complete`: Mark milestones.

### Mentorship & Chat (`api/v1/mentorship` & `api/v1/chat`)
- `GET /mentorship/search`: Find mentors by career goal.
- `POST /connections/request`: Send mentorship request.
- `GET /chat/connections`: Get active student-mentor pairs.
- `GET /chat/messages/{user_id}`: Fetch message history.
- `POST /chat/send`: Send real-time messages.

---

## 4. Database Schema Overview (SQLAlchemy Models)

### Users (`models/users.py`)
- `User`: id, email, hashed_password, role, full_name, profile_data (JSONB), progress (JSONB).

### Assessments (`models/assessments.py` & `models/compass.py`)
- `Question`: id, module, text, options (JSONB), category.
- `AssessmentResult`: id, user_id, module, score_data (JSONB), completed_at.

### Careers & Roadmaps (`models/careers.py` & `models/roadmaps.py`)
- `Career`: id, title, description, skills_required, industries.
- `Roadmap`: id, user_id, career_id, steps (JSONB), current_step, is_active.

### Mentorship (`models/mentorship.py`)
- `MentorProfile`: user_id, bio, expertise, rating.
- `ConnectionRequest`: sender_id, receiver_id, status (pending/accepted/rejected).

---

## 5. Mobile-Web Consistency Checklist

| Feature | Web Status | Mobile Status | Action Needed |
| :--- | :--- | :--- | :--- |
| **Likert Sliders** | Implemented (1-5) | Standard Buttons | Update to custom slider for EQ/Orientation |
| **Progress Saving** | Active (`save-progress`) | Missing | Implement `saveTestProgress` in Flutter |
| **Aptitude Grade Logic**| Strict 45-question pool | Basic fetch | Align `AptitudePool` logic in Flutter |
| **Profile Builder** | Dedicated flow | Combined with Test | Separate Profile Creation from Assessment |
| **Mentor Discovery** | Card-based Search | List View | Add filtering by 'Career Goal' as per web |
| **Video Call** | Dyte Integration | Basic Placeholder | Integrate Dyte Flutter SDK |

---

## 6. How it Works (Flow Example: Personality Test)
1. **Frontend** calls `GET /api/v1/assessments/questions/personality`.
2. **Backend** fetches questions from `questions` table where `module='personality'`.
3. **User** answers 20+ questions (1-5 scale).
4. **Frontend** calculates "Contradictions" (if user answers opposite values for the same trait).
5. **Frontend** calls `POST /api/v1/assessments/submit-generic` with `answers` and `contradictions`.
6. **Backend** calculates Big Five scores, updates `user.profile_data`, and marks `user.progress['personality_done'] = true`.
7. **Dashboard** refreshes, showing the next step unlocked.
