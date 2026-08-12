PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  role TEXT NOT NULL CHECK(role IN ('teacher','student','admin')),
  display_name TEXT NOT NULL,
  email TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS students (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  school_name TEXT,
  class_name TEXT,
  current_form INTEGER CHECK(current_form BETWEEN 1 AND 5),
  active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS submissions (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  teacher_id TEXT,
  title TEXT,
  subject TEXT NOT NULL DEFAULT 'Bahasa Melayu',
  form INTEGER CHECK(form BETWEEN 1 AND 5),
  assessment_type TEXT,
  source_type TEXT NOT NULL CHECK(source_type IN ('photo','pdf','scan')),
  original_r2_key TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'uploaded' CHECK(status IN ('uploaded','preprocessing','ocr','mapping','needs_review','confirmed','failed')),
  overall_ocr_confidence REAL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(student_id) REFERENCES students(id),
  FOREIGN KEY(teacher_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS submission_pages (
  id TEXT PRIMARY KEY,
  submission_id TEXT NOT NULL,
  page_no INTEGER NOT NULL,
  page_r2_key TEXT NOT NULL,
  processed_r2_key TEXT,
  quality_score REAL,
  rotation_degrees REAL,
  perspective_fixed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(submission_id, page_no),
  FOREIGN KEY(submission_id) REFERENCES submissions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS questions (
  id TEXT PRIMARY KEY,
  submission_id TEXT NOT NULL,
  page_id TEXT NOT NULL,
  question_no TEXT,
  crop_r2_key TEXT,
  question_text TEXT,
  student_answer TEXT,
  teacher_correction TEXT,
  teacher_mark TEXT CHECK(teacher_mark IN ('correct','wrong','partial','unmarked','uncertain')),
  awarded_mark REAL,
  max_mark REAL,
  ocr_question_confidence REAL,
  ocr_answer_confidence REAL,
  mark_detection_confidence REAL,
  mapping_confidence REAL,
  diagnosis_confidence REAL,
  review_status TEXT NOT NULL DEFAULT 'pending' CHECK(review_status IN ('pending','auto_accepted','needs_review','teacher_confirmed','teacher_corrected')),
  source_bbox_json TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(submission_id) REFERENCES submissions(id) ON DELETE CASCADE,
  FOREIGN KEY(page_id) REFERENCES submission_pages(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS curriculum_nodes (
  id TEXT PRIMARY KEY,
  form INTEGER CHECK(form BETWEEN 1 AND 5),
  domain TEXT NOT NULL,
  sk_code TEXT,
  sp_code TEXT,
  micro_skill TEXT,
  label TEXT NOT NULL,
  official_text TEXT,
  source_ref TEXT,
  active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS question_skill_evidence (
  id TEXT PRIMARY KEY,
  question_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  curriculum_node_id TEXT NOT NULL,
  error_code TEXT,
  result TEXT NOT NULL CHECK(result IN ('correct','partial','wrong','unknown')),
  evidence_weight REAL NOT NULL DEFAULT 1.0,
  mapping_confidence REAL,
  diagnosis_confidence REAL,
  source_type TEXT,
  confirmed_by_teacher INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(question_id) REFERENCES questions(id) ON DELETE CASCADE,
  FOREIGN KEY(student_id) REFERENCES students(id),
  FOREIGN KEY(curriculum_node_id) REFERENCES curriculum_nodes(id)
);

CREATE TABLE IF NOT EXISTS skill_mastery (
  student_id TEXT NOT NULL,
  curriculum_node_id TEXT NOT NULL,
  mastery_score REAL,
  confidence TEXT CHECK(confidence IN ('low','medium','high')),
  trend TEXT CHECK(trend IN ('improving','stable','declining','insufficient_data')),
  weakness_state TEXT CHECK(weakness_state IN ('observation','possible_weakness','confirmed_weakness','persistent_weakness','improving_weakness','resolved_monitoring')),
  evidence_count INTEGER NOT NULL DEFAULT 0,
  last_evidence_at TEXT,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(student_id, curriculum_node_id),
  FOREIGN KEY(student_id) REFERENCES students(id),
  FOREIGN KEY(curriculum_node_id) REFERENCES curriculum_nodes(id)
);

CREATE TABLE IF NOT EXISTS prerequisite_edges (
  from_node_id TEXT NOT NULL,
  to_node_id TEXT NOT NULL,
  relation TEXT NOT NULL,
  PRIMARY KEY(from_node_id, to_node_id, relation),
  FOREIGN KEY(from_node_id) REFERENCES curriculum_nodes(id),
  FOREIGN KEY(to_node_id) REFERENCES curriculum_nodes(id)
);

CREATE TABLE IF NOT EXISTS remediation_plans (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  curriculum_node_id TEXT NOT NULL,
  weakness_state TEXT,
  root_cause_node_id TEXT,
  plan_json TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','completed','superseded','cancelled')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(student_id) REFERENCES students(id),
  FOREIGN KEY(curriculum_node_id) REFERENCES curriculum_nodes(id),
  FOREIGN KEY(root_cause_node_id) REFERENCES curriculum_nodes(id)
);

CREATE TABLE IF NOT EXISTS review_events (
  id TEXT PRIMARY KEY,
  teacher_id TEXT NOT NULL,
  submission_id TEXT NOT NULL,
  question_id TEXT,
  field_name TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT,
  reason TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(teacher_id) REFERENCES users(id),
  FOREIGN KEY(submission_id) REFERENCES submissions(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)
);

CREATE INDEX IF NOT EXISTS idx_submissions_student ON submissions(student_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_questions_submission ON questions(submission_id);
CREATE INDEX IF NOT EXISTS idx_evidence_student_skill ON question_skill_evidence(student_id, curriculum_node_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mastery_student ON skill_mastery(student_id, weakness_state, mastery_score);
CREATE INDEX IF NOT EXISTS idx_review_submission ON review_events(submission_id, created_at DESC);
