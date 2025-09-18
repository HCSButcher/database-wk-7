

--  Database and Schema 
DROP DATABASE IF EXISTS library_db;
CREATE DATABASE library_db
  DEFAULT CHARACTER SET = utf8mb4
  DEFAULT COLLATE = utf8mb4_unicode_ci;
USE library_db;


-- publishers

DROP TABLE IF EXISTS publishers;
CREATE TABLE publishers (
  publisher_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  address TEXT,
  website VARCHAR(255),
  UNIQUE KEY uq_publisher_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- authors

DROP TABLE IF EXISTS authors;
CREATE TABLE authors (
  author_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  bio TEXT,
  UNIQUE KEY uq_author_name (first_name, last_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- categories

DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(255),
  UNIQUE KEY uq_category_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- books

DROP TABLE IF EXISTS books;
CREATE TABLE books (
  book_id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(500) NOT NULL,
  isbn VARCHAR(20) NULL,
  publisher_id INT NULL,
  publication_year YEAR NULL,
  pages INT NULL,
  language VARCHAR(50) DEFAULT 'English',
  summary TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_book_isbn (isbn),
  CONSTRAINT fk_books_publisher FOREIGN KEY (publisher_id)
    REFERENCES publishers(publisher_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- book_authors (junction)

DROP TABLE IF EXISTS book_authors;
CREATE TABLE book_authors (
  book_id INT NOT NULL,
  author_id INT NOT NULL,
  author_order TINYINT UNSIGNED DEFAULT 1,
  PRIMARY KEY (book_id, author_id),
  CONSTRAINT fk_ba_book FOREIGN KEY (book_id)
    REFERENCES books(book_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_ba_author FOREIGN KEY (author_id)
    REFERENCES authors(author_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- book_categories (junction)

DROP TABLE IF EXISTS book_categories;
CREATE TABLE book_categories (
  book_id INT NOT NULL,
  category_id INT NOT NULL,
  PRIMARY KEY (book_id, category_id),
  CONSTRAINT fk_bc_book FOREIGN KEY (book_id)
    REFERENCES books(book_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_bc_category FOREIGN KEY (category_id)
    REFERENCES categories(category_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- copies

DROP TABLE IF EXISTS copies;
CREATE TABLE copies (
  copy_id INT AUTO_INCREMENT PRIMARY KEY,
  book_id INT NOT NULL,
  copy_number VARCHAR(50) NOT NULL,
  barcode VARCHAR(100) NULL,
  acquisition_date DATE,
  condition ENUM('NEW','GOOD','FAIR','POOR') DEFAULT 'GOOD',
  available BOOLEAN DEFAULT TRUE,
  CONSTRAINT uq_book_copy_number UNIQUE (book_id, copy_number),
  CONSTRAINT uq_copy_barcode UNIQUE (barcode),
  CONSTRAINT fk_copy_book FOREIGN KEY (book_id)
    REFERENCES books(book_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- members

DROP TABLE IF EXISTS members;
CREATE TABLE members (
  member_id INT AUTO_INCREMENT PRIMARY KEY,
  membership_number VARCHAR(50) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(30),
  address TEXT,
  join_date DATE DEFAULT (CURRENT_DATE),
  active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- librarians

DROP TABLE IF EXISTS librarians;
CREATE TABLE librarians (
  librarian_id INT AUTO_INCREMENT PRIMARY KEY,
  employee_number VARCHAR(50) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE,
  hired_date DATE,
  active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- loans

DROP TABLE IF EXISTS loans;
CREATE TABLE loans (
  loan_id INT AUTO_INCREMENT PRIMARY KEY,
  copy_id INT NOT NULL,
  member_id INT NOT NULL,
  librarian_id INT NULL,
  loan_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  due_date DATETIME NOT NULL,
  return_date DATETIME NULL,
  status ENUM('ON_LOAN','RETURNED','OVERDUE','LOST') DEFAULT 'ON_LOAN',
  CONSTRAINT fk_loan_copy FOREIGN KEY (copy_id)
    REFERENCES copies(copy_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_loan_member FOREIGN KEY (member_id)
    REFERENCES members(member_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_loan_librarian FOREIGN KEY (librarian_id)
    REFERENCES librarians(librarian_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  INDEX idx_loans_member (member_id),
  INDEX idx_loans_copy (copy_id),
  INDEX idx_loans_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- reservations

DROP TABLE IF EXISTS reservations;
CREATE TABLE reservations (
  reservation_id INT AUTO_INCREMENT PRIMARY KEY,
  book_id INT NOT NULL,
  member_id INT NOT NULL,
  reserved_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME NULL,
  fulfilled BOOLEAN DEFAULT FALSE,
  CONSTRAINT fk_res_book FOREIGN KEY (book_id)
    REFERENCES books(book_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_res_member FOREIGN KEY (member_id)
    REFERENCES members(member_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  INDEX idx_res_member (member_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Optional view and indexes

DROP VIEW IF EXISTS vw_active_loans;
CREATE VIEW vw_active_loans AS
SELECT
  l.loan_id,
  l.copy_id,
  c.book_id,
  b.title,
  l.member_id,
  m.first_name AS member_first,
  m.last_name  AS member_last,
  l.loan_date,
  l.due_date,
  l.return_date,
  l.status
FROM loans l
JOIN copies c ON l.copy_id = c.copy_id
JOIN books b ON c.book_id = b.book_id
JOIN members m ON l.member_id = m.member_id
WHERE l.status <> 'RETURNED';

CREATE INDEX idx_books_title ON books(title(200));
CREATE INDEX idx_books_pubyear ON books(publication_year);
CREATE INDEX idx_authors_name ON authors(last_name, first_name);

--  Sample Data 
-- For smooth bulk insertion with foreign keys, temporarily disable FK checks
SET FOREIGN_KEY_CHECKS = 0;

-- ---------- publishers ----------
INSERT INTO publishers (name, address, website) VALUES
('Academic Press','123 University Ave, Townsville','https://academic.example.com'),
('Global Science Publishing','45 Research Rd, Metropolis','https://globalscience.example.com'),
('Open Research Press','PO Box 12, Knowledge City','https://openresearch.example.com');

-- ---------- authors ----------
INSERT INTO authors (first_name, last_name, bio) VALUES
('Alice','Johnson','Epidemiologist and researcher in infectious diseases.'),
('Brian','Smith','Data scientist focusing on public health analytics.'),
('Carmen','Lee','Virologist with focus on coronaviruses.'),
('David','Kim','Medical doctor and clinical researcher.');

-- ---------- categories ----------
INSERT INTO categories (name, description) VALUES
('Epidemiology','Studies of disease spread and control'),
('Virology','Virus biology and pathogenesis'),
('Clinical Trials','Clinical studies and trial reports'),
('Public Health','Health policy and population studies');

-- ---------- books ----------
INSERT INTO books (title, isbn, publisher_id, publication_year, pages, language, summary) VALUES
('COVID-19: Early Studies and Data','978-0-123456-47-2',1,2020,320,'English','Collection of early studies on COVID-19.'),
('SARS-CoV-2: Virology and Immune Response','978-1-234567-89-7',2,2021,280,'English','Detailed virology of SARS-CoV-2.'),
('Clinical Trials in a Pandemic','978-0-987654-32-1',3,2022,210,'English','Design and results of clinical trials during pandemics.'),
('Public Health Responses to Emerging Diseases','978-0-192837-46-5',1,2019,400,'English','Policy and public health responses.');

-- ---------- book_authors ----------
-- Map authors to books
INSERT INTO book_authors (book_id, author_id, author_order) VALUES
(1,1,1), -- Book 1 by Alice Johnson
(1,2,2), -- Book 1 coauthored by Brian Smith
(2,3,1), -- Book 2 by Carmen Lee
(3,4,1), -- Book 3 by David Kim
(4,2,1); -- Book 4 by Brian Smith

-- ---------- book_categories ----------
INSERT INTO book_categories (book_id, category_id) VALUES
(1,1),(1,4),   -- Book 1: Epidemiology, Public Health
(2,2),(2,1),   -- Book 2: Virology, Epidemiology
(3,3),         -- Book 3: Clinical Trials
(4,4);         -- Book 4: Public Health

-- ---------- copies ----------
INSERT INTO copies (book_id, copy_number, barcode, acquisition_date, condition, available) VALUES
(1,'C1','BCODE0001','2020-05-10','GOOD',TRUE),
(1,'C2','BCODE0002','2020-06-01','GOOD',TRUE),
(2,'C1','BCODE0003','2021-03-12','NEW',TRUE),
(3,'C1','BCODE0004','2022-01-15','NEW',TRUE),
(4,'C1','BCODE0005','2019-09-20','FAIR',TRUE);

-- ---------- members ----------
INSERT INTO members (membership_number, first_name, last_name, email, phone, address, join_date, active) VALUES
('M0001','Grace','Miller','grace.miller@example.com','+123456789','10 Elm St, Townsville','2020-02-15',TRUE),
('M0002','Henry','Owen','henry.owen@example.com','+123456780','22 Oak Ave, Townsville','2021-07-01',TRUE),
('M0003','Ivy','Nguyen','ivy.nguyen@example.com','+123456781','55 Pine Rd, Townsville','2019-11-05',TRUE);

-- ---------- librarians ----------
INSERT INTO librarians (employee_number, first_name, last_name, email, hired_date, active) VALUES
('E1001','Lara','Peters','lara.peters@library.example.com','2018-06-01',TRUE),
('E1002','Omar','Diaz','omar.diaz@library.example.com','2019-08-15',TRUE);

-- ---------- loans ----------
-- Create some loans: loan a copy to a member
INSERT INTO loans (copy_id, member_id, librarian_id, loan_date, due_date, return_date, status) VALUES
(1,1,1,'2024-08-01 10:00:00','2024-08-15 23:59:59',NULL,'ON_LOAN'),
(3,2,2,'2024-07-10 14:30:00','2024-07-24 23:59:59','2024-07-23 09:00:00','RETURNED');

-- Mark copy 1 as not available because it's on loan
UPDATE copies SET available = FALSE WHERE copy_id = 1;

-- ---------- reservations ----------
INSERT INTO reservations (book_id, member_id, reserved_at, expires_at, fulfilled) VALUES
(2,3,'2024-09-01 09:00:00','2024-09-08 23:59:59',FALSE);

-- Re-enable foreign key checks after inserts
SET FOREIGN_KEY_CHECKS = 1;

--  Sample Queries to Verify Data 
-- Show tables
SELECT 'Tables in library_db' AS info;
SHOW TABLES;

-- Show a few rows from main tables
SELECT * FROM publishers;
SELECT * FROM authors;
SELECT * FROM categories;
SELECT book_id, title, isbn, publication_year FROM books;
SELECT * FROM copies;
SELECT membership_number, first_name, last_name, email FROM members;
SELECT employee_number, first_name, last_name FROM librarians;

-- Active loans view
SELECT * FROM vw_active_loans LIMIT 10;

-- Join example: book title with authors
SELECT b.title, a.first_name, a.last_name
FROM books b
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
ORDER BY b.book_id, ba.author_order;

-- Count books per category
SELECT c.name AS category, COUNT(bc.book_id) AS num_books
FROM categories c
LEFT JOIN book_categories bc ON c.category_id = bc.category_id
GROUP BY c.category_id, c.name;

-- Current availability of copies
SELECT b.title, cp.copy_number, cp.available
FROM copies cp
JOIN books b ON cp.book_id = b.book_id
ORDER BY b.title, cp.copy_number;

-- Recent reservations
SELECT r.reservation_id, b.title, m.first_name, m.last_name, r.reserved_at, r.expires_at, r.fulfilled
FROM reservations r
JOIN books b ON r.book_id = b.book_id
JOIN members m ON r.member_id = m.member_id
ORDER BY r.reserved_at DESC;

-- End of script
