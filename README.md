# Bonsai Asset Index

Bonsai Asset Index is Sensu's community repository for assets, currently
hosted at [bonsai.sensu.io](bonsai.sensu.io). 

This is an opens source project, with a Ruby on Rails framework. The code is designed to be easy for you to understand and facilitate your contributions. To that end, the goal of this README is to introduce you to the project and get you up and running. 

If you want to contribute to Bonsai Asset Index, read the [contributor's
workflow](https://github.com/sensu/bonsai-asset-index/blob/master/CONTRIBUTING.md)
for license information and helpful tips to get you started. 

If you have questions, feature ideas, or other suggestions, please [open a
GitHub Issue](https://github.com/sensu/bonsai-asset-index/issues/new).

## Requirements

- Ruby 2.5.1
- PostgreSQL 9.2+
- Redis 2.4+

## Development

### Setup Using Docker Compose

1. Make sure [Docker](https://www.docker.com/get-started) and [Docker Compose](https://docs.docker.com/compose/gettingstarted/) are installed locally.
2. In the project root, copy the file .env.example to .env and change the keys and secrets to work in your local environment (see below).
3. From the project root, run "docker-compose build" to create your docker images
4. Create the database:  "docker-compose run web rake db:create"
5. Run migrations:  "docker-compose run web rake db:migrate"
6. Run seeds:  "docker-compose run web rake db:seed"
7. Launch app & services: "docker-compose up"
8. The app should now be available at http://localhost:3000
9. (Optional) To run byebug; docker-compose run --service-ports web. Be aware, the background jobs do not run with this operation.
11. (Optional) To run tests; docker-compose run -e "RAILS_ENV=test" web rspec

### ENV Variable Descriptions
The ENV allows you to customize your environmental variables.  Most work by default, but those that require information to function properly are: 
1. SENDGRID_API_KEY
2. AIRBRAKE project id and api key
3. AWS_S3	 key id, access key, region and bucket
4. GITHUB client id, client secret and access token

### Setting up Admin
1. In the rails console find your user record `user = User.find_by(email: "your@email.address")`
2. Add Admin authority `user.roles(:admin)`

### Rollout Gem Options

### API Docs

### 'Exotic Gems'

### Production Environment Setup

### Miscellanous

# License

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Copyright:**       | Copyright (c) 2018 Sensu, Inc.
| **License:**         | Apache License, Version 2.0

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
