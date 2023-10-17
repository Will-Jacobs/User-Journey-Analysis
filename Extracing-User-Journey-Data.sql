SET SESSION group_concat_max_len = 100000;

WITH
	paid_users AS
		(SELECT
			user_id,
			date_purchased AS first_purchase_date,
			CASE 
				WHEN purchase_type = 0 THEN 'Monthly'
				WHEN purchase_type = 1 THEN 'Quarterly'
				WHEN purchase_type = 2 THEN 'Yearly'
                ELSE 'Other'
			END AS subscription_type,
			purchase_price AS price
		FROM
			student_purchases
		WHERE (user_id, date_purchased) IN 
			(SELECT 
				user_id,
                MIN(date_purchased)
			FROM
				student_purchases
			GROUP BY user_id) 
				AND date_purchased BETWEEN '2023-01-01 00:00:00' AND '2023-03-31 23:59:59' AND purchase_price > 0
        ORDER BY user_id),
	visitor_user_id AS
		(SELECT
			fv.visitor_id,
            p.user_id
		FROM 
			front_visitors fv
				JOIN
			paid_users p ON fv.user_id = p.user_id),
    user_paths AS        
		(SELECT
			f.visitor_id,
            vui.user_id,
			f.session_id,
			f.event_source_url,
			f.event_destination_url,
			f.event_date,
            pu.subscription_type
		FROM
			front_interactions f
				JOIN
			visitor_user_id vui ON f.visitor_id = vui.visitor_id
				JOIN
			paid_users pu ON vui.user_id = pu.user_id),
	event_and_source_url AS
		(SELECT
            session_id,
            CASE event_source_url
				WHEN 'https://365datascience.com/' THEN 'Homepage'
				WHEN 'https://365datascience.com/login/' THEN 'Log in'
				WHEN 'https://365datascience.com/signup/' THEN 'Sign up'
				WHEN 'https://365datascience.com/resources-center/' THEN 'Resources center'
				WHEN 'https://365datascience.com/courses/' THEN 'Courses'
				WHEN 'https://365datascience.com/career-tracks/' THEN 'Career tracks'
				WHEN 'https://365datascience.com/upcoming-courses/' THEN 'Upcoming courses'
				WHEN 'https://365datascience.com/career-track-certificate/' THEN 'Career track certificate'
				WHEN 'https://365datascience.com/course-certificate/' THEN 'Course certificate'
				WHEN 'https://365datascience.com/success-stories/' THEN 'Success stories'
				WHEN 'https://365datascience.com/blog/' THEN 'Blog'
				WHEN 'https://365datascience.com/pricing/' THEN 'Pricing'
				WHEN 'https://365datascience.com/about-us/' THEN 'About us'
				WHEN 'https://365datascience.com/instructors/' THEN 'Instructors'
				WHEN 'https://365datascience.com/checkout/ and contains coupon' THEN 'Coupon'
				WHEN 'https://365datascience.com/checkout/ and does not contain coupon' THEN 'Checkout'
				ELSE 'Other'
			END AS event_source_url,
			CASE event_destination_url
				WHEN 'https://365datascience.com/' THEN 'Homepage'
				WHEN 'https://365datascience.com/login/' THEN 'Log in'
				WHEN 'https://365datascience.com/signup/' THEN 'Sign up'
				WHEN 'https://365datascience.com/resources-center/' THEN 'Resources center'
				WHEN 'https://365datascience.com/courses/' THEN 'Courses'
				WHEN 'https://365datascience.com/career-tracks/' THEN 'Career tracks'
				WHEN 'https://365datascience.com/upcoming-courses/' THEN 'Upcoming courses'
				WHEN 'https://365datascience.com/career-track-certificate/' THEN 'Career track certificate'
				WHEN 'https://365datascience.com/course-certificate/' THEN 'Course certificate'
				WHEN 'https://365datascience.com/success-stories/' THEN 'Success stories'
				WHEN 'https://365datascience.com/blog/' THEN 'Blog'
				WHEN 'https://365datascience.com/pricing/' THEN 'Pricing'
				WHEN 'https://365datascience.com/about-us/' THEN 'About us'
				WHEN 'https://365datascience.com/instructors/' THEN 'Instructors'
				WHEN 'https://365datascience.com/checkout/ and contains coupon' THEN 'Coupon'
				WHEN 'https://365datascience.com/checkout/ and does not contain coupon' THEN 'Checkout'
				ELSE 'Other'
			END AS event_destination_url
		FROM
			user_paths),
	combined_url AS
		(SELECT
			esu.session_id,
			CONCAT(esu.event_source_url, '-', esu.event_destination_url) AS source_to_destination
		FROM 
			event_and_source_url esu),
	session_url AS
		(SELECT
			cu.session_id,
			GROUP_CONCAT(cu.source_to_destination SEPARATOR '-') AS session_url
		FROM
			combined_url cu
		GROUP BY cu.session_id)
SELECT
	up.user_id,
    su.session_id,
    up.subscription_type,
    su.session_url
FROM
	session_url su
		JOIN
	user_paths up ON su.session_id = up.session_id
ORDER BY user_id;