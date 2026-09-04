SELECT 
    ad_date,
    source,
    campaign_name,
    adset_name,
    utm_campaign,
    SUM(spend)       AS total_spend,
    SUM(clicks)      AS total_clicks,
    SUM(impressions) AS total_impressions,
    SUM(reach)       AS total_reach,
    SUM(leads)       AS total_leads,
    SUM(value)       AS total_value
FROM (
    -- 1. Facebook Ads
    SELECT 
        fabd.ad_date,
        'Facebook'::text AS source,
        fc.campaign_name,
        fa.adset_name,
        CASE 
            WHEN fabd.url_parameters IS NULL OR substring(fabd.url_parameters FROM 'utm_campaign=([^&]+)') IS NULL THEN NULL
            WHEN lower(substring(fabd.url_parameters FROM 'utm_campaign=([^&]+)')) = 'nan' THEN NULL
            ELSE (
                SELECT convert_from(
                    CAST(
                        E'\\x' || string_agg(
                            CASE 
                                WHEN length(r.m[1]) = 1 THEN encode(convert_to(r.m[1], 'SQL_ASCII'), 'hex')
                                ELSE substring(r.m[1] from 2 for 2)
                            END, 
                            ''
                        ) AS bytea
                    ), 
                    'UTF8'
                )
                FROM regexp_matches(replace(lower(substring(fabd.url_parameters FROM 'utm_campaign=([^&]+)')), '+', ' '), '%[0-9a-f][0-9a-f]|.', 'gi') AS r(m)
            )
        END AS utm_campaign,
        COALESCE(fabd.spend, 0) AS spend,
        COALESCE(fabd.clicks, 0) AS clicks,
        COALESCE(fabd.impressions, 0) AS impressions,
        COALESCE(fabd.reach, 0) AS reach,
        COALESCE(fabd.leads, 0) AS leads,
        COALESCE(fabd.value, 0) AS value
    FROM facebook_ads_basic_daily fabd
    LEFT JOIN facebook_campaign fc ON fabd.campaign_id = fc.campaign_id
    LEFT JOIN facebook_adset fa ON fabd.adset_id = fa.adset_id

    UNION ALL

    -- 2. Google Ads
    SELECT 
        gabd.ad_date,
        'Google'::text AS source,
        gabd.campaign_name,
        gabd.adset_name,
        CASE 
            WHEN gabd.url_parameters IS NULL OR substring(gabd.url_parameters FROM 'utm_campaign=([^&]+)') IS NULL THEN NULL
            WHEN lower(substring(gabd.url_parameters FROM 'utm_campaign=([^&]+)')) = 'nan' THEN NULL
            ELSE (
                SELECT convert_from(
                    CAST(
                        E'\\x' || string_agg(
                            CASE 
                                WHEN length(r.m[1]) = 1 THEN encode(convert_to(r.m[1], 'SQL_ASCII'), 'hex')
                                ELSE substring(r.m[1] from 2 for 2)
                            END, 
                            ''
                        ) AS bytea
                    ), 
                    'UTF8'
                )
                FROM regexp_matches(replace(lower(substring(gabd.url_parameters FROM 'utm_campaign=([^&]+)')), '+', ' '), '%[0-9a-f][0-9a-f]|.', 'gi') AS r(m)
            )
        END AS utm_campaign,
        COALESCE(gabd.spend, 0) AS spend,
        COALESCE(gabd.clicks, 0) AS clicks,
        COALESCE(gabd.impressions, 0) AS impressions,
        COALESCE(gabd.reach, 0) AS reach,
        COALESCE(gabd.leads, 0) AS leads,
        COALESCE(gabd.value, 0) AS value
    FROM google_ads_basic_daily gabd
) sub
GROUP BY ad_date, source, campaign_name, adset_name, utm_campaign
ORDER BY ad_date, source, campaign_name;