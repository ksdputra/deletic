# Deletic

Soft deletes for ActiveRecord done right (highly influenced by Discard and Paranoia)

## What does this do?

A simple ActiveRecord mixin to add conventions for flagging records as deleted.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'deletic', git: 'git://github.com/ksdputra/deletic.git'
```

And then execute:

    $ bundle

## Usage

**Prepare deletic column**

You can either generate a migration using:
```
rails generate migration add_deleted_at_to_posts deleted_at:datetime:index
```

or create one yourself like the one below:
``` ruby
class AddDeleticToPosts < ActiveRecord::Migration[5.0]
  def change
    add_column :posts, :deleted_at, :datetime
    add_index :posts, :deleted_at
  end
end
```

**Declare acts_as_deletic in a model**

Declare acts_as_deletic in a model

``` ruby
class Post < ActiveRecord::Base
  acts_as_deletic
end
```

**acts_as_deletic options**

By default, Deletic will use column deleted_at and use default scope.
Also please note that callbacks for save and update are NOT run when soft deleting/restoring a record.
If you want to override this, you can give options:

```ruby
class Post < ActiveRecord::Base
  acts_as_deletic column: :removed_at,
                  without_default_scope: true,
                  skip_ar_callbacks: false
end
```

#### All available methods

Soft delete is filling column deleted_at with `Time.current`.
Restore is nulling column deleted_at.

```ruby
post = Post.first
post.soft_destroy    # to soft delete a record
post.soft_destroy!   # to soft delete a record, throw error Deletic::RecordNotDeleted if failed
post.soft_delete     # to soft delete a record, skip Deletic callbacks
post.restore         # to restore a soft deleted record
post.restore!        # to restore a soft deleted record, throw error Deletic::RecordNotRestored if failed
post.reconstruct     # to restore a soft deleted record, skip Deletic callbacks
post.soft_deleted?   # to check if a record is soft deleted
post.kept?           # to check if a record is not soft deleted

# Class method
Post.soft_destroy_all   # soft delete all records
Post.soft_destroy_all!  # soft delete all records, throw error Deletic::RecordNotDeleted if failed
Post.soft_delete_all    # soft delete all records with single SQL UPDATE, skip Deletic callbacks
Post.restore_all        # restore all records
Post.restore_all!       # restore all records, throw error Deletic::RecordNotRestored if failed
Post.reconstruct_all    # restore all records with single SQL UPDATE, skip Deletic callbacks

# Scope: with default scope
Post.all                 # return all kept record 
Post.kept                # return all kept record
Post.soft_deleted        # return all soft deleted record
Post.with_soft_deleted   # return all record

# Scope: without default scope
Post.all                 # return all record 
Post.kept                # return all kept record
Post.soft_deleted        # return all soft deleted record
Post.with_soft_deleted   # return all record
```

#### Soft delete a record

```ruby
# With default scope
Post.all             # => [#<Post id: 1, ...>]
Post.kept            # => [#<Post id: 1, ...>]
Post.soft_deleted    # => []

post = Post.first    # => #<Post id: 1, ...>
post.soft_destroy     # => true
post.soft_destroy!    # => Deletic::RecordNotDeleted: Failed to soft delete the record
post.soft_deleted?   # => true
post.kept?           # => false
post.deleted_at      # => 2020-04-01 00:00:00 +0700

Post.all             # => []
Post.kept            # => []
Post.soft_deleted    # => [#<Post id: 1, ...>]


# Without default scope
Post.all             # => [#<Post id: 1, ...>]
Post.kept            # => [#<Post id: 1, ...>]
Post.soft_deleted    # => []

post = Post.first    # => #<Post id: 1, ...>
post.soft_destroy     # => true
post.soft_destroy!    # => Deletic::RecordNotDeleted: Failed to soft delete the record
post.soft_deleted?   # => true
post.kept?           # => false
post.deleted_at      # => 2020-04-01 00:00:00 +0700

Post.all             # => [#<Post id: 1, ...>]
Post.kept            # => []
Post.soft_deleted    # => [#<Post id: 1, ...>]
```

***From a controller***

Controller actions need a small modification to soft delete records instead of deleting them. Just replace `destroy` with `soft_destroy`.

``` ruby
def destroy
  @post.soft_destroy
  redirect_to users_url, notice: "Post removed"
end
```


#### Restore a record

```ruby
post = Post.first   # => #<Post id: 1, ...>
post.restore      # => true
post.restore!     # => Deletic::RecordNotRestored: Failed to restore the record
post.deleted_at   # => nil
```

***From a controller***

```ruby
def update
  @post.restore
  redirect_to users_url, notice: "Post restored"
end
```

#### Working with associations

Under paranoia, soft deleting a record will destroy any `dependent: :destroy`
associations. Probably not what you want! This leads to all dependent records
also needing to be `acts_as_paranoid`, which makes restoring awkward: paranoia
handles this by restoring any records which have their deleted_at set to a
similar timestamp. Also, it doesn't always make sense to mark these records as
deleted, it depends on the application.

A better approach is to simply mark the one record as soft deleted, and use SQL
joins to restrict finding these if that's desired.

#### Deletic Callbacks

Callbacks can be run before, after, or around the soft delete and restore operations.
A likely use is soft deleting or deleting associated records (but see "Working with associations" for an alternative).

``` ruby
class Comment < ActiveRecord::Base
  acts_as_deletic
end

class Post < ActiveRecord::Base
  acts_as_deletic

  has_many :comments

  after_soft_destroy do
    comments.soft_destroy_all
  end

  after_restore do
    comments.restore_all
  end
end
```

If you don't want to run Deletic Callbacks when soft deleting, you can use `soft_delete`.
If you don't want to run Deletic Callbacks when restoring, you can use `reconstruct`.


#### Performance tuning
`soft_destroy_all` and `restore_all` is intended to behave like `destroy_all` which has callbacks, validations, and does one query per record. If performance is a big concern, you may consider replacing it with:

`soft_delete_all`
or
`reconstruct_all`

#### Working with Devise

A common use case is to apply Deletic to a User record. Even though a user has been soft deleted they can still login and continue their session.
If you are using Devise and wish for soft deleted users to be unable to login and stop their session you can override Devise's method.

```ruby
class User < ActiveRecord::Base
  def active_for_authentication?
    super && !soft_deleted?
  end
end
```

## Non-features

* Special handling of AR counter cache columns - The counter cache counts the total number of records, both kept and soft deleted.
* Recursive soft deletes (like AR's dependent: destroy) - This can be avoided using queries (See "Working with associations") or emulated using callbacks.
* Recursive restores - This concept is fundamentally broken, but not necessary if the recursive soft deletes are avoided.

## Why not paranoia or acts_as_paranoid?

Paranoia and [acts_as_paranoid](https://github.com/ActsAsParanoid/acts_as_paranoid) both
attempt to emulate deletes by setting a column and adding a default scope on the
model. This requires some ActiveRecord hackery, and leads to some surprising
and awkward behaviour.

* A default scope is added to hide soft-deleted records, which necessitates
  adding `.with_deleted` to associations or anywhere soft-deleted records
  should be found. :disappointed:
* Adding `belongs_to :child, -> { with_deleted }` helps, but doesn't work for
  joins and eager-loading [before Rails 5.2](https://github.com/rubysherpas/paranoia/issues/355)
* `delete` is overridden (`really_delete` will actually delete the record) :unamused:
* `destroy` is overridden (`really_destroy` will actually delete the record) :pensive:
* `dependent: :destroy` associations are deleted when performing soft-destroys :scream:
* requiring any dependent records to also be `acts_as_paranoid` to avoid losing data. :grimacing:

There are some use cases where these behaviours make sense: if you really did
want to _almost_ delete the record. More often developers are just looking to
hide some records, or mark them as inactive.

Deletic takes a different approach. It doesn't override any ActiveRecord
methods and instead simply provides convenience methods and scopes for
soft deleting (hiding), restoring, and querying records.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake default` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Acknowledgments

* [Discard](https://github.com/jhawthorn/discard)
* [Paranoia](https://github.com/rubysherpas/paranoia)