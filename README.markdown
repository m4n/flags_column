FlagsColumn
===========

A RubyOnRails plugin that extends ActiveRecord to provide enhanced access to bit-flagged columns.


Example
=======

Prepare your model:

    class AddVisibleToFlagsToPosts < ActiveRecord::Migration
      def self.up
        add_column :posts, :visible_to, :integer
      end

      def self.down
        remove_column :posts, :visible_to
      end
    end

    class Post < ActiveRecord::Base
      # Mark a column as a bit-flagged integer,
      # provide the flag names and their bit positions,
      # and optionally set one or more default flags.
      #
      flags_column :visible_to,
                   { :admins => 0, :members => 1, :friends => 2 },
                   :initial => [:members, :friends],
                   :accessible => true

    end

Run script/console:

    >> Post.flagged_column_names
    => [:visible_to]

    >> Post.flagged_columns
    => {:visible_to=>{:flags=>{:admins=>0, :members=>1, :friends=>2}, :initial=>[:members, :friends]}

    >> Post.visible_to_flags
    => [:members, :admins, :friends]

    >> Post.visible_to_bit_flags
    => {:admins=>1, :members=>2, :friends=>4}

    >> Post.visible_to_default_mask
    => 6

    >> Post.mask_visible_to(:friends, :admins)
    => 5

    >> Post.unmask_visible_to(3)
    => [:admins, :members]

    >> p = Post.new
    => #<Post id: nil, title: nil, body: nil, visible_to: 6, ...>

    >> p.visible_to
    => 6

    >> p.visible_to_flags
    => [:members, :friends]

    >> p.visible_to_admins?
    => false

    >> p.visible_to_members?
    => true

    >> p.visible_to_friends
    => true

    >> p.visible_to_admins_and_members?
    => false

    >> p.visible_to_members_and_friends?
    => true

    >> p.visible_to_none?
    => false

    >> p.visible_to_all?
    => false

    >> p.visible_to_admins = true
    => true

    >> p.visible_to_admins_and_members_and_friends?
    => true

    >> p.visible_to_members_and_admins = false
    => false

    >> p.visible_to_flags
    => [:friends]

    >> p.save
    => #<Post id: 1, title: nil, body: nil, visible_to: 4, ...>

    >> Post.all(:conditions => { :visible_to => Post.mask_visible_to(:admins, :members) })
    =>[#<Post ...>, #<Post ...>, ...]



Copyright (c) 2008-2011 Martin Andert, released under the MIT license.

