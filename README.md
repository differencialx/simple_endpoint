# SimpleEndpoint
[![<differencialx>](https://circleci.com/gh/differencialx/simple_endpoint.svg?style=svg)](https://circleci.com/gh/differencialx/simple_endpoint)
[![Gem Version](https://img.shields.io/gem/v/simple_endpoint.svg)](https://rubygems.org/gems/simple_endpoint)

Dry-matcher free implementation of trailblazer endpoint.

## Installation
Add this to your Gemfile:

```ruby
gem 'simple_endpoint', '~> 2.0.0'
```

## Getting Started

Include simple endpoint to your base controller

```ruby
class ApplicationController < ActionController::Base
  include SimpleEndpoint::Controller
end
```

Define `cases` to specify trailblazer operation result handling.

```ruby
class ApplicationController < ActionController::Base
  include SimpleEndpoint::Controller

  cases do
    match(:success) { |result| result.success? }
    match(:invalid) { |result| result.failure? }
  end
end
```
or
```ruby
class ApplicationController < ActionController::Base
  include SimpleEndpoint::Controller

  private

  def default_cases
    {
      success: -> (result) { result.success? },
      invalid: -> (result) { result.failure? }
    }
  end
end
```

Define `handler` to specify how to handle each case

```ruby
class ApplicationController < ActionController::Base
  include SimpleEndpoint::Controller

  handler do
    on(:success) { |result, **opts| render json: result['model'], **opts, status: 200 }
    on(:invalid) { |result, **| render json: result['contract.default'].errors, serializer: ErrorSerializer, status: :unprocessable_entity }
  end
end
```
or `default_handler` method
```ruby
class ApplicationController < ActionController::Base
  include SimpleEndpoint::Controller

  private

  def default_handler
    {
      success: -> (result, **opts) { render json: result['model'], **opts, status: 200 },
      invalid: -> (result, **) { render json: result['contract.default'].errors, serializer: ErrorSerializer, status: :unprocessable_entity }
    }
  end
end
```

`OperationIsNotHandled` error will be raised if `cases`/`#default_cases` doesn't contain case for specific operation result.

`UnhandledResultError` will be raised if `handler`/`#default_hadnler` doesn't contain for some cases.

`NotImplementedError` will be raised if `cases`/`#default_cases` or `handler`/`#default_hadnler` aren't defined.


### #endpoint method

Now you are able to use `endpoint` method at other controllers

`#endpoint` method has next signature:

| Key | Required | Default value | Description  |
|---|---|---|---|
| `:operation` | yes | - | Traiblazer operation class |
| `:different_cases`| no | {} | Cases that should be redefined for exact `#endpoint` call |
| `:different_handler` | no | {} | Case of handler that should be handled in different way |
| `:options` | no | {} | Additional hash which will be merged to `#ednpoint_options` method result before operation execution |
| `:before_response` | no | {} | Allow to process code before specific case handler |
| `:renderer_options` | no | {} | Allow to pass serializer options from controller and Will available inside handler as second parameter.


#### Simple endpoint call
```ruby
class PostsController < ApplicationController
  def create
    endpoint operation: Post::Create
  end
end
```

#### Redefining cases for specific controller

If you need to redefine operation result handling for specific controller you can do next

It will redefine or add only **these** cases
```ruby
class PostsController < ApplicationController
  cases do
    match(:success) { |result| result.success? && is_it_raining? }
    match(:invalid) { |result| result.failure? && is_vasya_in_the_house? }
  end

  def create
    endpoint operation: Post::Create
  end

  private

  def is_it_raining?
    WeatherForecast.for_today.raining?
  end

  def is_vasya_in_the_house?
    User.find_by(login: 'vasya').signed_in?
  end
end
```
If you want to remove parent cases use `inherit` option
It will remove cases and add new ones
```ruby
class PostsController < ApplicationController
  cases(inherit: false) do
    match(:success) { |result| result.success? && is_it_raining? }
    match(:invalid) { |result| result.failure? && is_vasya_in_the_house? }
  end

  def create
    endpoint operation: Post::Create
  end

  private

  def is_it_raining?
    WeatherForecast.for_today.raining?
  end

  def is_vasya_in_the_house?
    User.find_by(login: 'vasya').signed_in?
  end
end
```
or manually create `default_cases` method. Note that it'll override `ApplicationController#default_cases`
```ruby
class PostsController < ApplicationController
  def create
    endpoint operation: Post::Create
  end

  private

  def default_cases
    {
      success: -> (result) { result.success? && is_it_raining? },
      invalid: -> (result) { result.failure? && is_vasya_in_the_house? }
      ... # other cases
    }
  end

  def is_it_raining?
    WeatherForecast.for_today.raining?
  end

  def is_vasya_in_the_house?
    User.find_by(login: 'vasya').signed_in?
  end
end
```

#### Redefining cases for specific controller action

Code below will redefine only `success` operation handling logic of `cases`/`#default_cases`, it doesn't matter where `cases`/`#default_cases` was defined, at `ApplicationController` or `PostsController`

```ruby
class PostsController < ApplicationController
  def create
    cases { on(:success) { |result| result.success? && is_vasya_in_the_house? } }
    endpoint operation: Post::Create
  end

  private

  def is_vasya_in_the_house?
    User.find_by(login: 'vasya').signed_in?
  end
end
```
or
```ruby
class PostsController < ApplicationController
  def create
    endpoint operation:       Post::Create,
             different_cases: different_cases
  end

  private

  def different_cases
    {
      success: -> (result) { result.success? && is_vasya_in_the_house? }
    }
  end

  def is_vasya_in_the_house?
    User.find_by(login: 'vasya').signed_in?
  end
end
```

#### Redefining handler for specific controller

If you need to redefine handler logic, simply redefine `handler`. It'll redefine only `success` handler
```ruby
class PostsController < ApplicationController
  handler do
    on(:success) { |result, **| head :ok }
  end

  def create
    endpoint operation: Post::Create
  end
end
```
If you want remove parent handler settings you can use `inherit` option. It'll remove all other settings.
```ruby
class PostsController < ApplicationController
  handler(inherit: false) do
    on(:success) { |result, **| head :ok }
  end

  def create
    endpoint operation: Post::Create
  end
end
```
or redefine `default_handler` method
```ruby
class PostsController < ApplicationController
  def create
    endpoint operation: Post::Create
  end

  private

  def default_handler
    {
      success: -> (result, **) { head :ok }
    }
  end
end
```

#### Redefining handler for specific controller action

```ruby
class PostsController < ApplicationController
  def create
    handler { on(:success) { |result, **| render json: { message: 'Nice!' }, status: :created } }
    endpoint operation: Post::Create,
             different_handler: different_handler
  end
end

```
or
```ruby
class PostsController < ApplicationController
  def create
    endpoint operation: Post::Create,
             different_handler: different_handler
  end

  private

  def different_handler
    {
      success: -> (result, **) { render json: { message: 'Nice!' }, status: :created }
    }
  end
end
```

#### Defining default params for trailblazer operation

Default `#endpoint_options` method implementation

```ruby
  def endpoint_options
    { params: params }
  end
```

Redefining `endpoint_options`
It will extend existing options
```ruby
class PostsController < ApplicationController
  endpoint_options { { params: permitted_params } }

  def permitted_params
    params.permit(:some, :attributes)
  end
end
```
If you want to remove previously defined options you can use `inherit` option
```ruby
class PostsController < ApplicationController
  endpoint_options(inherit: false) { { params: permitted_params } }

  def permitted_params
    params.permit(:some, :attributes)
  end
end
```
Or redefine `endpoint_options` method
```ruby
class PostsController < ApplicationController

  private

  def endpoint_options
    { params: permitted_params }
  end

  def permitted_params
    params.permit(:some, :attributes)
  end
end
```

#### Passing additional params to operation

`options` will be merged with `#endpoint_options` method result and trailblazer operation will be executed with such params: `Post::Create.(params: params, current_user: current_user)`

```ruby
class PostsController < ApplicationController
  def create
    endpoint operation: Post::Create,
             options: { current_user: current_user }
  end
end
```

#### Before handler actions

You can do some actions before `#default_handler` execution

```ruby
class PostsController < ApplicationController
  def create
    before_response do
      on(:success) do |result, **|
        response.headers['Some-header'] = result[:some_data]
      end
    end
    endpoint operation: Post::Create
    end
  end
end
```
or
```ruby
class PostsController < ApplicationController
  def create
    endpoint operation: Post::Create,
             before_response: before_render_actions
    end
  end

  private

  def before_response_actions
    {
      success: -> (result, **) { response.headers['Some-header'] = result[:some_data] }
    }
  end
end
```

Code above will put data from operation result into response haeders before render


#### Pass additional options from controller

```ruby
class PostsController < ApplicationController
  def create
    endpoint operation: Post::Create,
             renderer_options: { serializer: SerializerClass }
    end
  end

  private

  def default_handler
    {
      # renderer_options will be available as **opts
      success: -> (result, **opts) { render json: result['model'], **opts, status: 200 },
      invalid: -> (result, **) { render json: result['contract.default'].errors, serializer: ErrorSerializer, status: :unprocessable_entity }
    }
  end
end
```
### Migration from v1 to v2
:warning::warning::warning:
**Be cautious while using v2.x.x. We executing blocks and lambdas explicitly on the instance of the class where `SimpleEndpoint::Controller` module were included. That's related to `handler`/`#default_handler`, `cases`/`#default_cases` and `before_response`.
If you are creating lambdas or blocks for handler and cases in different class with internal methods usage it won't work unlike the v1**
:warning::warning::warning:

```ruby
class Handler
  def self.call
    { 
      success: ->(result, **) { result.success? && some_method? }
    }
  end

  private

  def some_method?
    true
  end
end

class ApplicationController
  def default_handler
    # works with v1 but will cause an error in v2
    Handler.call
  end
end
```
