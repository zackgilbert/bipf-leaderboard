# Build In Public Fellowship Leaderboard

The following is a mini project built in Sinatra (Ruby) w/ Tailwind css that was started on 2023-03-09 at the request of @thisiskp_:
<img width="365" alt="Screen Shot 2023-03-09 at 9 18 49 PM" src="https://user-images.githubusercontent.com/432526/224217505-b4511728-1801-4548-96f8-f7b44278d68e.png">

It currently allows users to authenticate their Twitter account via OAuth and syncs their Twitter posts since the beginning of the fellowship on 2023-03-07 (`from:#{twitter_username} since:2023-03-07 exclude:replies exclude:retweets`).


Tasks Completed on 2023-03-09
- [x] Basic Sinatra app that displays a simple Tailwind table of auth'd users
- [x] User Twitter authentication
- [x] User Twitter account syncing after authentication
- [x] Added a force sync for logged in users for their own account
<img width="772" alt="Screen Shot 2023-03-09 at 9 19 53 PM" src="https://user-images.githubusercontent.com/432526/224217546-2184d982-43ab-4acc-bad1-cb6575e8b9a4.png">


Tasks Completed on 2023-03-10
- [x] Get setup on a server w/ proper domain
- [x] Separate Twitter / LinkedIn activity
- [x] Break out activity by weeks
- [x] Add daily streaks
<img width="778" alt="Screen Shot 2023-03-10 at 8 51 06 PM" src="https://user-images.githubusercontent.com/432526/224461141-b445006d-c9d4-4c6e-8d19-e21379f11d37.png">


Tasks Completed on 2023-03-11
- [x] Get IRB working using `irb -r ./app.rb`
- [x] Sort users by post activity
- [x] Add endpoint for regular twitter syncing

Todo:
- [ ] User LinkedIn authentication
- [ ] User LinkedIn account syncing after authentication
- [ ] Access webhooks from Twitter of new posts from auth'd users
- [ ] Access webhooks from LinkedIn of new posts from auth'd users
- [ ] Put in end date for syncing
