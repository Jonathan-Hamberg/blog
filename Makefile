delay:
	aws s3 sync ./public/ s3://jonathanhamberg.com --acl public-read
	aws cloudfront create-invalidation --distribution-id E2NTZVZYNFLF1 --paths "/*"
