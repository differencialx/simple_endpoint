# SimpleEndpoint

Dry-matcher free implementation of trailblazer endpoint.

## Installation
Add this to your Gemfile:

```ruby
gem 'simple_endpoint' # not released yet
gem 'simple_endpoint', github: 'differencialx/simple_endpoint', :branch => 'master'
```

## Getting Started

Include simple endpoint to your base controller

```ruby
class ApplicationController < ActionController::Base
  include SimpleEndpoint::Controller
end
```

Define `default_cases` method to specify trailblazer operation result handling

```ruby
class ApplicationController < ActionController::Base
  include SimpleEndpoint::Controller

  private

  def default_cases
    {
      success:         -> (result) { result.success? },
      invalid:         -> (result) { result.failure? },
      not_found:       -> (result) { result.failure? && result["result.model"] && result["result.model"].failure? },
      unauthenticated: -> (result) { result.failure? && result["result.policy.default"] && result["result.policy.default"].failure? }
    }
  end
end
```

Define `default_handler` method to specify how to handle each case

```ruby
class ApplicationController < ActionController::Base
  include SimpleEndpoint::Controller

  private

  def default_handler
    -> (kase, result) do
      case kase
      when :success then render :json result['serializer'], status: 200
      else
        # just in case you forgot to add handler for some of cases
        SimpleEndpoint::UnhadledResultError, 'Oh nooooo!!! Really???!!'
      end
    end
  end
end
```

You'll receive `NotImplementedError` if `default_cases` or `default_handler` methods aren't defined.

### #endpoint method

Now you are able to use `endpoint` method at other controllers

`#endpoint` method has next signature:

| Key | Required | Default value | Description  |
|---|---|---|---|
| `:operation` | yes | - | Traiblazer operation class |
| `:different_cases`| no | {} | Cases that should be redefined for exact `#endpoint` call |
| `:options` | no | `#endpoint_options` method result | By default it is `{ params: params }` hash, more details about `#endpoint_options` method here |


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

Note that it'll override `ApplicationController#default_cases`

#### Redefining cases for specific controller action

Code below will redefine only `success` operation handling logic of `#default_cases` method, it doesn't matter where `#default_cases` was defied, at `ApplicationController` or `PostsController`

```ruby
class PostsController < ApplicationController
  def create
    endpoint operation:       Post::Create,
             different_cases: different_cases
  end

  private

  def different_cases
    {
      success: (result) { result.success? && is_vasya_in_the_house? }
    }
  end

  def is_vasya_in_the_house?
    User.find_by(login: 'vasya').signed_in?
  end
end
```

#### Redefining handler for specific controller

If you need to redefine handler logic, simply redefine `#default_handler` method

```ruby
class PostsController < ApplicationController
  def create
    endpoint operation: Post::Create
  end

  private

  def default_handler
    -> (kase, result) do
      case kase
      when :success then head :ok
      else
        # just in case you forgot to add handler for some of cases
        SimpleEndpoint::UnhadledResultError, 'Oh nooooo!!! Really???!!'
      end
    end
  end
end
```
#### Passing additional params to operation

```ruby
class PostsController < ApplicationController
  def create
    endpoint operation: Post::Create,
             options: endpoint_options(current_user: current_user)
  end
end
```

#### Before handler actions

You can do some actions before `#default_handler` invoke

```ruby
class PostsController < ApplicationController
  def create
    endpoint(operation: Post::Create) do |kase, result|
      -> (kase, result) do
        case kase
        when :success then response.headers['Some-header'] = result[:some_data]
        end
      end
    end 
  end
end
```

Code above will put data from operation result into response haeders before render
