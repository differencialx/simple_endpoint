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
      success: -> (result) { result.success? },
      invalid: -> (result) { result.failure? }
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
    {
      success: -> (result) { render json: result['model'], **result['render_options'] status: 200 },
      invalid: -> (result) { render json: result['contract.default'].errors, serializer: ErrorSerializer, status: :unprocessable_entity }
    }
  end
end
```

`OperationIsNotHandled` error will be raised if `#default_cases` doesn't contain case for specific operation result.

`UnhadledResultError` will be raised if `#default_handler` doesn't contain for some cases.

`NotImplementedError` will be raised if `default_cases` or `default_handler` methods aren't defined.


### #endpoint method

Now you are able to use `endpoint` method at other controllers

`#endpoint` method has next signature:

| Key | Required | Default value | Description  |
|---|---|---|---|
| `:operation` | yes | - | Traiblazer operation class |
| `:different_cases`| no | {} | Cases that should be redefined for exact `#endpoint` call |
| `:different_handler` | no | {} | Case of handler that should be handled in different way |
| `:options` | no | {} | Additional hash which will be merged to `#ednpoint_options` method result before operation execution |
| `:before_render` | no | {} | Allow to process code before specific case handler |


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

Code below will redefine only `success` operation handling logic of `#default_cases` method, it doesn't matter where `#default_cases` was defined, at `ApplicationController` or `PostsController`

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

If you need to redefine handler logic, simply redefine `#default_handler` method

```ruby
class PostsController < ApplicationController
  def create
    endpoint operation: Post::Create
  end

  private

  def default_handler
    {
      success: -> (result) { head :ok }
    }
  end
end
```

#### Redefining handler for specific controller action

```ruby
class PostsController < ApplicationController
  def create
    endpoint operation: Post::Create,
             different_handler: different_handler
  end

  private

  def different_handler
    {
      success: -> (result) { render json: { message: 'Nice!' }, status: :created }
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
    endpoint operation: Post::Create,
             before_response: before_render_actions
    end 
  end

  private

  def before_response_actions
    {
      success: -> (result) { response.headers['Some-header'] = result[:some_data] }
    }
  end
end
```

Code above will put data from operation result into response haeders before render
