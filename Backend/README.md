# FocusPet Backend MVP Scaffold

This folder contains a beginner-friendly local backend scaffold for FocusPet.

The goal of this stage is not to build the full AI system yet. We are setting up a clean local backend that can grow into the future architecture described in:

- `AI_BACKEND_ARCHITECTURE.md`
- `AGENTS_v2.md`
- `RAG_AND_SKILLS_DESIGN.md`

## Why This Stack

This scaffold uses:

- `Python`
- `FastAPI`
- `Uvicorn`
- `Pydantic`
- `SQLite`
- `SQLAlchemy`

Why:

- FastAPI is easy to read for beginners.
- It gives you a working API server with very little code.
- It includes automatic API docs at `/docs`.
- SQLite is perfect for local MVP work because it stores data in one local file.
- SQLAlchemy lets you define database tables with Python classes.
- This is simple enough for local learning, but still structured enough for future growth.

## Current Scope

Included now:

- basic server setup
- health check endpoint
- local SQLite database
- persisted task module
- persisted focus session module
- AI module placeholder
- local environment example
- task soft delete
- task recycle-bin flow
- fixed task status enum
- auto-calculated task progress
- task list filtering by status
- focus session updates task time
- DeepSeek-powered split-task endpoint
- first formal backend Skill: split_task
- second formal backend Skill: suggest_next_action
- minimal SkillRegistry
- lightweight Orchestrator layer

Not included yet:

- auth
- Redis
- RAG
- skills execution
- production deployment

## Folder Structure

```text
Backend/
  app/
    api/
      routes/
        ai.py
        focus_sessions.py
        health.py
        tasks.py
      router.py
    core/
      config.py
    db/
      base.py
      database.py
      init_db.py
    models/
      focus_session.py
      task.py
    schemas/
      ai.py
      focus_sessions.py
      tasks.py
    services/
      ai_service.py
      focus_session_service.py
      task_service.py
    skills/
      registry.py
      suggest_next_action_skill.py
      split_task_skill.py
    orchestrator/
      simple_orchestrator.py
    main.py
  .env.example
  requirements.txt
  README.md
```

## Local Setup

### 1. Go into the backend folder

```bash
cd Backend
```

### 2. Create a virtual environment

```bash
python3 -m venv .venv
```

### 3. Activate it

macOS / zsh:

```bash
source .venv/bin/activate
```

### 4. Install dependencies

```bash
pip install -r requirements.txt
```

### 5. Create your local env file

```bash
cp .env.example .env
```

Then open `.env` and set your real DeepSeek key:

```env
DEEPSEEK_API_KEY=your_real_deepseek_api_key
```

### 6. Start the server

```bash
uvicorn app.main:app --reload
```

When the server starts for the first time, it will automatically create:

- a `data/` folder
- a `data/focuspet.db` SQLite database file
- the `tasks` table
- the `focus_sessions` table

When the server starts later, it will also try to update the local `tasks` table if older columns are missing.
This keeps the project beginner-friendly because you do not need a separate migration tool yet.

### 7. Open the API docs

Open:

```text
http://127.0.0.1:8000/docs
```

## Available Endpoints

- `GET /health`
- `GET /api/v1/tasks`
- `GET /api/v1/tasks?status=todo`
- `GET /api/v1/tasks/deleted`
- `GET /api/v1/tasks/{id}`
- `POST /api/v1/tasks`
- `PATCH /api/v1/tasks/{id}`
- `DELETE /api/v1/tasks/{id}`
- `POST /api/v1/tasks/{id}/restore`
- `GET /api/v1/focus-sessions`
- `POST /api/v1/focus-sessions`
- `POST /api/v1/ai/split-task`
- `POST /api/v1/ai/suggest-next-action`

## DeepSeek LLM Setup

This backend now uses DeepSeek through the OpenAI-compatible SDK.
The `split_task` and `suggest_next_action` capabilities are now wrapped as formal Skills in the backend.

The API key is loaded from `.env` through `app/core/config.py`.

Required env variable:

```env
DEEPSEEK_API_KEY=your_real_deepseek_api_key
```

If the key is missing, the AI endpoints return a `400` error with a clear message.

## Skill Registry And Orchestrator

The backend now also has:

- a small SkillRegistry in `app/skills/registry.py`
- a lightweight orchestrator in `app/orchestrator/simple_orchestrator.py`

What the registry does:

- keeps a simple mapping from skill name to skill object
- makes it easier to add more skills later

What the orchestrator does:

- asks the registry for the right skill
- runs that skill
- gives the service layer one simple place to call AI behavior

This is still intentionally small.
It is not a full agent system yet, but it prepares the code for future evolution.

## SplitTask Skill

`split_task` is now implemented as a lightweight Skill in `app/skills/split_task_skill.py`.

What this means:

- the Skill has a clear name
- the Skill has a short description
- the Skill exposes one focused `run(user_input: str)` method

Why this helps:

- today, the route still behaves exactly the same
- later, an orchestrator can choose between multiple skills
- later, RAG can be added before or around a skill without rewriting the route contract

For now, `app/services/ai_service.py` simply forwards the split-task request to this Skill.

## SuggestNextAction Skill

`suggest_next_action` is implemented as a lightweight Skill in `app/skills/suggest_next_action_skill.py`.

What it does:

- accepts a small list of current tasks
- prefers a task that is already `in_progress`
- otherwise picks one unfinished task that seems easy to start
- asks the LLM for one short, gentle, concrete next action

This Skill is different from `split_task`:

- `split_task` turns one big goal into multiple steps
- `suggest_next_action` gives only one best next move from the current task list

If the request contains no unfinished tasks, this endpoint now returns a gentle fallback:

```json
{
  "message": "先写下一件你最想推进的事吧。"
}
```

## Task Status Rules

Tasks now use a fixed status enum instead of any free-form string.

Allowed values:

- `todo`
- `in_progress`
- `paused`
- `completed`

If you send another value in `PATCH /api/v1/tasks/{id}`, FastAPI will reject the request with a validation error.

The same status values can also be used for task list filtering.

Example:

- `/api/v1/tasks?status=todo`
- `/api/v1/tasks?status=in_progress`

## Task Progress Rules

Task progress is now calculated by the backend.

Simple formula:

- `progress = spent_minutes / estimated_minutes`

Safe rules:

- if `estimated_minutes` is missing, progress becomes `0.0`
- if `estimated_minutes` is `0` or invalid, progress becomes `0.0`
- progress is always clamped into the `0.0` to `1.0` range

Examples:

- `spent_minutes = 15`, `estimated_minutes = 60` -> `progress = 0.25`
- `spent_minutes = 90`, `estimated_minutes = 60` -> `progress = 1.0`
- no `estimated_minutes` -> `progress = 0.0`

## Task Auto-Complete Rule

The backend can now auto-update task status when progress reaches the end.

Simple rule:

- if `progress >= 1.0`, set `status = completed`
- but do not override `paused`

Examples:

- a `todo` task reaching `1.0` becomes `completed`
- an `in_progress` task reaching `1.0` becomes `completed`
- a `paused` task reaching `1.0` stays `paused`

This rule is applied when task time changes.

## Soft Delete

Deleting a task is now a soft delete.

This means:

- the row stays in the database
- `is_deleted` becomes `true`
- `deleted_at` stores the delete time
- normal task APIs do not return deleted tasks anymore
- the recycle-bin API can list deleted tasks
- the restore API can bring them back

This is helpful because the backend keeps the record instead of removing it forever.

## How Data Flows

The request path now works like this:

1. `API route`
   A request enters a route file such as `app/api/routes/tasks.py`.

2. `Service`
   The route passes the request data to a service like `TaskService`.

3. `Database model`
   The service uses SQLAlchemy models such as `Task` or `FocusSession`.

4. `SQLite database file`
   SQLAlchemy saves and reads the data from `data/focuspet.db`.

5. `Response schema`
   The service converts the database row into a clean API response model.

This keeps the code easier to understand because each layer has one job.

## Test The Backend Locally

### Health check

```bash
curl http://127.0.0.1:8000/health
```

### Create a task

```bash
curl -X POST http://127.0.0.1:8000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Write backend notes",
    "notes": "Keep this simple",
    "estimated_minutes": 30
  }'
```

### List tasks

```bash
curl http://127.0.0.1:8000/api/v1/tasks
```

### List tasks filtered by status

Only the normal, non-deleted task list supports this filter.

```bash
curl http://127.0.0.1:8000/api/v1/tasks?status=todo
```

```bash
curl http://127.0.0.1:8000/api/v1/tasks?status=in_progress
```

### Get one task by id

Replace `TASK_ID` with a real task id returned from the create task API.

```bash
curl http://127.0.0.1:8000/api/v1/tasks/TASK_ID
```

### List deleted tasks

This is the recycle-bin list.

```bash
curl http://127.0.0.1:8000/api/v1/tasks/deleted
```

### Update a task with PATCH

PATCH only updates the fields you send.

```bash
curl -X PATCH http://127.0.0.1:8000/api/v1/tasks/TASK_ID \
  -H "Content-Type: application/json" \
  -d '{
    "status": "paused",
    "spent_minutes": 25
  }'
```

You do not need to send `progress`.
The backend recalculates it from `spent_minutes` and `estimated_minutes`.
If progress reaches `1.0` and the task is not paused, the backend also changes status to `completed`.

### Delete a task

This is now a soft delete, not a hard delete.

```bash
curl -X DELETE http://127.0.0.1:8000/api/v1/tasks/TASK_ID
```

### Restore a deleted task

```bash
curl -X POST http://127.0.0.1:8000/api/v1/tasks/TASK_ID/restore
```

### Create a focus session

```bash
curl -X POST http://127.0.0.1:8000/api/v1/focus-sessions \
  -H "Content-Type: application/json" \
  -d '{
    "duration_seconds": 1500,
    "timer_mode": "countUp"
  }'
```

### Create a focus session linked to a task

If you pass a `task_id`, the backend now checks whether that task exists and is not deleted.
Then it adds focus time into that task's `spent_minutes`.
After that, the backend recalculates `progress`.
If progress reaches `1.0` and the task is not paused, status becomes `completed`.

Simple rule:

- added task minutes = `duration_seconds // 60`

Example:

- `1500` seconds adds `25` minutes
- `1800` seconds adds `30` minutes

```bash
curl -X POST http://127.0.0.1:8000/api/v1/focus-sessions \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "TASK_ID",
    "duration_seconds": 1500,
    "timer_mode": "countUp"
  }'
```

### List focus sessions

```bash
curl http://127.0.0.1:8000/api/v1/focus-sessions
```

### Split one task with DeepSeek

```bash
curl -X POST http://127.0.0.1:8000/api/v1/ai/split-task \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "我想完成产品原型和需求梳理"
  }'
```

Expected response shape:

```json
{
  "tasks": [
    "先整理产品目标和核心功能",
    "列出主要页面和用户流程",
    "补充每个页面的关键内容",
    "完成原型初稿",
    "检查并优化需求描述"
  ]
}
```

### Suggest one next action with DeepSeek

```bash
curl -X POST http://127.0.0.1:8000/api/v1/ai/suggest-next-action \
  -H "Content-Type: application/json" \
  -d '{
    "tasks": [
      {
        "id": "1",
        "title": "准备自我介绍",
        "status": "todo",
        "progress": 0.0
      },
      {
        "id": "2",
        "title": "整理项目案例",
        "status": "in_progress",
        "progress": 0.4
      }
    ]
  }'
```

Expected response shape:

```json
{
  "message": "先把正在推进的项目案例整理成 3 个要点。"
}
```

## Test The AI Endpoint In /docs

1. Start the server with `uvicorn app.main:app --reload`.
2. Open [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs).
3. Find `POST /api/v1/ai/split-task` or `POST /api/v1/ai/suggest-next-action`.
4. Click `Try it out`.
5. For `split-task`, use a request body like this:

```json
{
  "user_input": "我想这周完成毕业论文开题报告"
}
```

6. For `suggest-next-action`, use a request body like this:

```json
{
  "tasks": [
    {
      "id": "1",
      "title": "准备自我介绍",
      "status": "todo",
      "progress": 0.0
    },
    {
      "id": "2",
      "title": "整理项目案例",
      "status": "in_progress",
      "progress": 0.4
    }
  ]
}
```

7. Click `Execute`.
8. If everything is set correctly:

- `split-task` returns a `tasks` array
- `suggest-next-action` returns one `message` string

Common cases:

- If `DEEPSEEK_API_KEY` is missing, you should see a `400` response.
- If the DeepSeek request fails, you should see a `500` response.

## Beginner Test Flow

Use this small flow to test the new logic.

### 1. Create one task

```bash
curl -X POST http://127.0.0.1:8000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Study API changes",
    "notes": "Beginner test",
    "estimated_minutes": 60
  }'
```

Save the returned id as `TASK_ID`.

### 2. Check the default status

```bash
curl http://127.0.0.1:8000/api/v1/tasks/TASK_ID
```

You should see:

- `status` is `todo`
- `is_deleted` is `false`
- `deleted_at` is `null`

### 3. Update the status with a valid enum value

```bash
curl -X PATCH http://127.0.0.1:8000/api/v1/tasks/TASK_ID \
  -H "Content-Type: application/json" \
  -d '{
    "status": "in_progress"
  }'
```

### 4. Try an invalid status

```bash
curl -X PATCH http://127.0.0.1:8000/api/v1/tasks/TASK_ID \
  -H "Content-Type: application/json" \
  -d '{
    "status": "active"
  }'
```

You should get a validation error because `active` is no longer allowed.

### 5. Create a focus session linked to the task

```bash
curl -X POST http://127.0.0.1:8000/api/v1/focus-sessions \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "TASK_ID",
    "duration_seconds": 1500,
    "timer_mode": "countUp"
  }'
```

Then read the task again:

```bash
curl http://127.0.0.1:8000/api/v1/tasks/TASK_ID
```

You should see `spent_minutes` increased by `25`.
You should also see `progress` updated automatically.

For example:

- if `estimated_minutes` is `60`
- and `spent_minutes` becomes `25`
- then `progress` should be about `0.4167`

If a later update or focus session brings `progress` to `1.0`, the task should become `completed` unless it is `paused`.

### 6. Soft delete the task

```bash
curl -X DELETE http://127.0.0.1:8000/api/v1/tasks/TASK_ID
```

### 7. Confirm the task is hidden from the normal list

```bash
curl http://127.0.0.1:8000/api/v1/tasks
```

The deleted task should no longer appear in the normal task list.

If you call:

```bash
curl http://127.0.0.1:8000/api/v1/tasks/TASK_ID
```

you should get `404 Task not found.`

### 8. Check the recycle bin

```bash
curl http://127.0.0.1:8000/api/v1/tasks/deleted
```

You should see the deleted task in this list.

### 9. Restore the deleted task

```bash
curl -X POST http://127.0.0.1:8000/api/v1/tasks/TASK_ID/restore
```

You should see:

- `is_deleted` is `false`
- `deleted_at` is `null`

### 10. Confirm the task is back in the normal list

```bash
curl http://127.0.0.1:8000/api/v1/tasks
```

Now the task should appear again.

If you call:

```bash
curl http://127.0.0.1:8000/api/v1/tasks/deleted
```

the restored task should no longer be in the deleted list.

### 11. Test task filtering

Update one task to `todo` and another task to `paused`, then try:

```bash
curl http://127.0.0.1:8000/api/v1/tasks?status=todo
```

```bash
curl http://127.0.0.1:8000/api/v1/tasks?status=paused
```

Each request should only return tasks with that status.
Deleted tasks should still stay hidden from these filtered normal lists.

### 12. Test auto-complete

Create a task with `estimated_minutes = 60`, then set `spent_minutes = 60`:

```bash
curl -X PATCH http://127.0.0.1:8000/api/v1/tasks/TASK_ID \
  -H "Content-Type: application/json" \
  -d '{
    "spent_minutes": 60
  }'
```

The response should show:

- `progress` is `1.0`
- `status` is `completed`

### 13. Test paused task behavior

Set a task to paused first:

```bash
curl -X PATCH http://127.0.0.1:8000/api/v1/tasks/TASK_ID \
  -H "Content-Type: application/json" \
  -d '{
    "status": "paused"
  }'
```

Then make its time reach full progress:

```bash
curl -X PATCH http://127.0.0.1:8000/api/v1/tasks/TASK_ID \
  -H "Content-Type: application/json" \
  -d '{
    "spent_minutes": 60
  }'
```

The response should show:

- `progress` is `1.0`
- `status` stays `paused`

## Notes About The Database

- SQLite stores data in `data/focuspet.db`
- soft-deleted tasks stay in the database file
- the API hides them by filtering `is_deleted = false`
- the recycle-bin API shows them by filtering `is_deleted = true`
- progress is recalculated from task time fields
- tasks auto-complete when progress reaches `1.0`, unless they are paused
- older task rows with invalid statuses are converted to `todo` on startup

- We are using SQLite because it is the easiest local database for MVP development.
- The database is just one file on disk: `Backend/data/focuspet.db`.
- You do not need to install a separate database server.
- If you delete that file, the local data is gone.
- The app will recreate the file and tables on next startup.

## What To Build Next

Recommended next steps:

1. Add simple due date fields and overdue task rules.
2. Add separate history queries for completed tasks and active tasks.
3. Add sorting options for due-soon or recently-updated tasks.
4. Add event ingestion for `focus_ended`, `home_opened`, and similar events.
5. Connect the iOS app to `POST /api/v1/ai/split-task`.
6. Build a small rule-based planner for deadline suggestions.
7. Add more AI endpoints only after this first LLM flow is stable.

## Notes

- This scaffold is intentionally simple.
- The AI route is intentionally simple and only handles split-task for now.
- For now, readability is more important than completeness.
