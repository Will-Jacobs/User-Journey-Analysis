
# !!! RUN THIS BEFORE QUERY !!!
SET SESSION group_concat_max_len = 100000;

WITH
	paid_users as
	(
		SELECT
			user_id,
            MIN(date_purchased) as first_order_date,
            CASE
				WHEN purchase_type = 0 THEN 'Monthly'
                WHEN purchase_type = 1 THEN 'Quarterly'
                WHEN purchase_type = 2 THEN 'Yearly'
                ELSE 'Other'
			END as subscription_type,
            purchase_price as price
		FROM 
			student_purchases
		GROUP BY user_id, subscription_type, price
        HAVING
			price > 0
            AND
            CAST(first_order_date as DATE) >= '2023-01-01'
            AND
            CAST(first_order_date as DATE) < '2023-04-01'
	),
    table_interactions as
    (
		SELECT
			p.user_id,
            i.visitor_id,
            i.session_id,
            i.event_source_url,
            i.event_destination_url,
            p.subscription_type
		FROM
			paid_users p
				JOIN
			front_visitors v ON p.user_id = v.user_id
				JOIN
			front_interactions i ON v.visitor_id = i.visitor_id
		WHERE
			i.event_date < p.first_order_date
	),
    table_aliases as
    (
		SELECT
			user_id,
            session_id,
            subscription_type,
            CASE
				WHEN event_source_url = 'https://365datascience.com/' THEN 'Homepage'
				WHEN event_source_url LIKE 'https://365datascience.com/login/%' THEN 'Log in'
				WHEN event_source_url LIKE 'https://365datascience.com/signup/%' THEN 'Sign up'
				WHEN event_source_url LIKE 'https://365datascience.com/resources-center/%' THEN 'Resources center'
				WHEN event_source_url LIKE 'https://365datascience.com/courses/%' THEN 'Courses'
				WHEN event_source_url LIKE 'https://365datascience.com/career-tracks/%' THEN 'Career tracks'
				WHEN event_source_url LIKE 'https://365datascience.com/upcoming-courses/%' THEN 'Upcoming courses'
				WHEN event_source_url LIKE 'https://365datascience.com/career-track-certificate/%' THEN 'Career track certificate'
				WHEN event_source_url LIKE 'https://365datascience.com/course-certificate/%' THEN 'Course certificate'
				WHEN event_source_url LIKE 'https://365datascience.com/success-stories/%' THEN 'Success stories'
				WHEN event_source_url LIKE 'https://365datascience.com/blog/%' THEN 'Blog'
				WHEN event_source_url LIKE 'https://365datascience.com/pricing/%' THEN 'Pricing'
				WHEN event_source_url LIKE 'https://365datascience.com/about-us/%' THEN 'About us'
				WHEN event_source_url LIKE 'https://365datascience.com/instructors/%' THEN 'Instructors'
				WHEN event_source_url LIKE 'https://365datascience.com/checkout/%' AND event_source_url LIKE '%coupon%' THEN 'Coupon'
				WHEN event_source_url LIKE 'https://365datascience.com/checkout/%' AND event_source_url NOT LIKE '%coupon%' THEN 'Checkout'
				ELSE 'Other'
			END as source_page_alias,
			CASE
				WHEN event_destination_url = 'https://365datascience.com/' THEN 'Homepage'
				WHEN event_destination_url LIKE 'https://365datascience.com/login/%' THEN 'Log in'
				WHEN event_destination_url LIKE 'https://365datascience.com/signup/%' THEN 'Sign up'
				WHEN event_destination_url LIKE 'https://365datascience.com/resources-center/%' THEN 'Resources center'
				WHEN event_destination_url LIKE 'https://365datascience.com/courses/%' THEN 'Courses'
				WHEN event_destination_url LIKE 'https://365datascience.com/career-tracks/%' THEN 'Career tracks'
				WHEN event_destination_url LIKE 'https://365datascience.com/upcoming-courses/%' THEN 'Upcoming courses'
				WHEN event_destination_url LIKE 'https://365datascience.com/career-track-certificate/%' THEN 'Career track certificate'
				WHEN event_destination_url LIKE 'https://365datascience.com/course-certificate/%' THEN 'Course certificate'
				WHEN event_destination_url LIKE 'https://365datascience.com/success-stories/%' THEN 'Success stories'
				WHEN event_destination_url LIKE 'https://365datascience.com/blog/%' THEN 'Blog'
				WHEN event_destination_url LIKE 'https://365datascience.com/pricing/%' THEN 'Pricing'
				WHEN event_destination_url LIKE 'https://365datascience.com/about-us/%' THEN 'About us'
				WHEN event_destination_url LIKE 'https://365datascience.com/instructors/%' THEN 'Instructors'
				WHEN event_destination_url LIKE 'https://365datascience.com/checkout/%' AND event_destination_url LIKE '%coupon%' THEN 'Coupon'
				WHEN event_destination_url LIKE 'https://365datascience.com/checkout/%' AND event_destination_url NOT LIKE '%coupon%' THEN 'Checkout'
				ELSE 'Other'
			END as destination_page_alias
		FROM
			table_interactions
	),
    table_concatenated as
    (
		SELECT
			user_id,
            session_id,
            subscription_type,
            CONCAT(source_page_alias, 
            '-',
            destination_page_alias) as source_destination
		FROM 
			table_aliases
    ),
    table_group_concatenated as
	(
		SELECT
			user_id,
            session_id,
            subscription_type,
            GROUP_CONCAT(source_destination SEPARATOR '-') as user_journey
		FROM
			table_concatenated
		GROUP BY session_id, user_id, subscription_type
    )
SELECT
	*
FROM
	table_group_concatenated
ORDER BY user_id, session_id;

		