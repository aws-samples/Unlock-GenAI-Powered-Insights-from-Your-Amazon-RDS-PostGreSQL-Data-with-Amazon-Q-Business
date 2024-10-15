```sql
/*
This test data represents a sustainability management system that tracks various sustainability projects,
their scores, and the stakeholders involved. Richard Roe, the Secrets Projects Custodian, has access only
to the "Secret Sustainability Project" (project_id 6), while Alejandro Rosalez, the General Projects Custodian,
has access to all the general sustainability projects (project_id 1-5) but not the secret project. The data
shows that there are 6 sustainability projects in total, allowing example.org to manage and monitor their
sustainability initiatives while maintaining the confidentiality of the sensitive project based on the
different access levels for Richard and Alejandro.
*/

CREATE TABLE sustainability_projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    project_description TEXT,
    start_date DATE,
    end_date DATE,
    budget DECIMAL(10,2),
    user_access VARCHAR(100)
);

CREATE TABLE sustainability_scores (
    score_id SERIAL PRIMARY KEY,
    project_id INT REFERENCES sustainability_projects(project_id),
    sustainability_score INT CHECK (sustainability_score >= 0 AND sustainability_score <= 100),
    status VARCHAR(50) CHECK (status IN ('Planned', 'In Progress', 'Completed')),
    user_access VARCHAR(100)
);

CREATE TABLE stakeholders (
    stakeholder_id SERIAL PRIMARY KEY,
    stakeholder_name VARCHAR(100) NOT NULL,
    stakeholder_role VARCHAR(50),
    project_id INT REFERENCES sustainability_projects(project_id),
    user_access VARCHAR(100)
);

INSERT INTO sustainability_projects (project_id, project_name, project_description, start_date, end_date, budget, user_access) 
VALUES 
(1, 'Solar Panel Installation', 'Install solar panels on the roof of the company headquarters.', '2022-03-01', '2022-09-30', 50000.00, 'alejandro_rosalez@example.org'),
(2, 'Waste Reduction Program', 'Implement a comprehensive waste management system to reduce landfill waste.', '2021-06-15', '2022-06-14', 25000.00, 'alejandro_rosalez@example.org'),
(3, 'Sustainable Forestry Initiative', 'Partner with a local forestry organization to plant and maintain a community forest.', '2023-01-01', '2025-12-31', 100000.00, 'alejandro_rosalez@example.org'),
(4, 'Energy Efficiency Upgrades', 'Upgrade the HVAC system and lighting to improve energy efficiency in the office building.', '2022-11-01', '2023-04-30', 75000.00, 'alejandro_rosalez@example.org'),
(5, 'Green Transportation Program', 'Provide incentives for employees to use public transportation or electric vehicles.', '2023-05-01', '2024-04-30', 30000.00, 'alejandro_rosalez@example.org'),
(6, 'Secret Sustainability Project', 'This is a confidential sustainability project that is not to be shared with the public.', '2023-05-01', '2024-04-30', 30000.00, 'richard_roe@example.org');

INSERT INTO sustainability_scores (project_id, sustainability_score, status, user_access) 
VALUES 
(1, 90, 'Completed', 'alejandro_rosalez@example.org'),
(2, 80, 'In Progress', 'alejandro_rosalez@example.org'),
(3, 75, 'Planned', 'alejandro_rosalez@example.org'),
(4, 85, 'In Progress', 'alejandro_rosalez@example.org'),
(5, 70, 'Planned', 'alejandro_rosalez@example.org'),
(6, 99, 'Completed', 'richard_roe@example.org');

INSERT INTO stakeholders (stakeholder_name, stakeholder_role, project_id, user_access) 
VALUES 
('John Doe', 'Project Manager', 1, 'alejandro_rosalez@example.org'),
('Jane Smith', 'Sustainability Coordinator', 2, 'alejandro_rosalez@example.org'),
('Robert Johnson', 'Environmental Consultant', 3, 'alejandro_rosalez@example.org'),
('Emily Williams', 'Energy Efficiency Specialist', 4, 'alejandro_rosalez@example.org'),
('Michael Brown', 'Transportation Coordinator', 5, 'alejandro_rosalez@example.org'),
('Secret Stakeholder', 'Confidential Sustainability Advisor', 6, 'richard_roe@example.org');

SELECT * FROM sustainability_projects; 
SELECT * FROM sustainability_scores; 
SELECT * FROM stakeholders;
```
