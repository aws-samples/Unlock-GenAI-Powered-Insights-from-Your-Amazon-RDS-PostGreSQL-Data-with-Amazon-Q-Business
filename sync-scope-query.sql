SELECT
    sp.project_id,
    sp.project_name,
    sp.user_access,
    CONCAT(
        'Project ID: ', sp.project_id, E'\n',
        'Project Name: ', sp.project_name, E'\n',
        'Project Description: ', sp.project_description, E'\n',
        'Start Date: ', sp.start_date, E'\n',
        'End Date: ', sp.end_date, E'\n',
        'Budget: ', sp.budget, E'\n',
        'Sustainability Score: ', ss.sustainability_score, E'\n',
        'Status: ', ss.status, E'\n',
        'Stakeholders:', E'\n',
        (
            SELECT STRING_AGG(
                CONCAT(' - ', stakeholder_name, ' (', stakeholder_role, ')'),
                E'\n'
            )
            FROM stakeholders
            WHERE project_id = sp.project_id
        )
    ) AS project_details
FROM
    sustainability_projects sp
JOIN
    sustainability_scores ss ON sp.project_id = ss.project_id
