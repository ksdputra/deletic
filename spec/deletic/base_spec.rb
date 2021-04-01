# frozen_string_literal: true

RSpec.describe Deletic::Base do
  context "with simple Post model" do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true
      end
    end

    context "a kept Post" do
      let!(:post) { Post.create!(title: "My very first post") }

      it "is included in the default scope" do
        expect(Post.all).to eq([post])
      end

      it "is included in kept scope" do
        expect(Post.kept).to eq([post])
      end

      it "is not included in soft_deleted scope" do
        expect(Post.soft_deleted).to eq([])
      end

      it "should not be soft_deleted?" do
        expect(post).not_to be_soft_deleted
      end

      it "should be kept?" do
        expect(post).to be_kept
      end

      describe '#soft_destroy' do
        it "sets deleted_at" do
          expect {
            post.soft_destroy
          }.to change { post.deleted_at }
        end

        it "sets deleted_at in DB" do
          expect {
            post.soft_destroy
          }.to change { post.reload.deleted_at }
        end
      end

      describe '#soft_destroy!' do
        it "sets deleted_at" do
          expect {
            post.soft_destroy!
          }.to change { post.deleted_at }
        end

        it "sets deleted_at in DB" do
          expect {
            post.soft_destroy!
          }.to change { post.reload.deleted_at }
        end
      end

      describe '#soft_delete' do
        it "sets deleted_at" do
          expect {
            post.soft_delete
          }.to change { post.deleted_at }
        end

        it "sets deleted_at in DB" do
          expect {
            post.soft_delete
          }.to change { post.reload.deleted_at }
        end
      end

      describe '#restore' do
        it "doesn't change deleted_at" do
          expect {
            post.restore
          }.not_to change { post.deleted_at }
        end

        it "doesn't change deleted_at in DB" do
          expect {
            post.restore
          }.not_to change { post.reload.deleted_at }
        end
      end

      describe '#restore!' do
        it "raises Deletic::RecordNotRestored" do
          expect {
            post.restore!
          }.to raise_error(Deletic::RecordNotRestored)
        end
      end

      describe '#reconstruct' do
        it "doesn't change deleted_at" do
          expect {
            post.reconstruct
          }.not_to change { post.deleted_at }
        end

        it "doesn't change deleted_at in DB" do
          expect {
            post.reconstruct
          }.not_to change { post.reload.deleted_at }
        end
      end
    end

    context "soft_deleted Post" do
      let!(:post) { Post.create!(title: "A soft_deleted post", deleted_at: Time.parse('2017-01-01')) }

      it "is included in the default scope" do
        expect(Post.all).to eq([post])
      end

      it "is not included in kept scope" do
        expect(Post.kept).to eq([])
      end

      it "is included in soft_deleted scope" do
        expect(Post.soft_deleted).to eq([post])
      end

      it "should be soft_deleted?" do
        expect(post).to be_soft_deleted
      end

      it "should not be kept?" do
        expect(post).to_not be_kept
      end

      describe '#soft_destroy' do
        it "doesn't change deleted_at" do
          expect {
            post.soft_destroy
          }.not_to change { post.deleted_at }
        end

        it "doesn't change deleted_at in DB" do
          expect {
            post.soft_destroy
          }.not_to change { post.reload.deleted_at }
        end
      end

      describe '#soft_destroy!' do
        it "raises Deletic::RecordNotDeleted" do
          expect {
            post.soft_destroy!
          }.to raise_error(Deletic::RecordNotDeleted)
        end
      end

      describe '#soft_delete' do
        it "doesn't change deleted_at" do
          expect {
            post.soft_delete
          }.not_to change { post.deleted_at }
        end

        it "doesn't change deleted_at in DB" do
          expect {
            post.soft_delete
          }.not_to change { post.reload.deleted_at }
        end
      end

      describe '#restore' do
        it "clears deleted_at" do
          expect {
            post.restore
          }.to change { post.deleted_at }.to(nil)
        end

        it "clears deleted_at in DB" do
          expect {
            post.restore
          }.to change { post.reload.deleted_at }.to(nil)
        end
      end

      describe '#restore!' do
        it "clears deleted_at" do
          expect {
            post.restore!
          }.to change { post.deleted_at }.to(nil)
        end

        it "clears deleted_at in DB" do
          expect {
            post.restore!
          }.to change { post.reload.deleted_at }.to(nil)
        end
      end

      describe '#reconstruct' do
        it "clears deleted_at" do
          expect {
            post.reconstruct
          }.to change { post.deleted_at }.to(nil)
        end

        it "clears deleted_at in DB" do
          expect {
            post.reconstruct
          }.to change { post.reload.deleted_at }.to(nil)
        end
      end
    end
  end

  context "with default scope" do
    with_model :WithDefaultScope, scope: :all do
      table do |t|
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic
      end
    end
    let(:klass) { WithDefaultScope }

    context "a kept record" do
      let!(:record) { klass.create! }

      it "is included in the default scope" do
        expect(klass.all).to eq([record])
      end

      it "is included in kept scope" do
        expect(klass.kept).to eq([record])
      end

      it "is included in with_soft_deleted scope" do
        expect(klass.with_soft_deleted).to eq([record])
      end

      it "is not included in soft_deleted scope" do
        expect(klass.soft_deleted).to eq([])
      end
    end

    context "a soft_deleted record" do
      let!(:record) { klass.create!(deleted_at: Time.current) }

      it "is not included in the default scope" do
        expect(klass.all).to eq([])
      end

      it "is not included in kept scope" do
        expect(klass.kept).to eq([])
      end

      it "is included in soft_deleted scope" do
        expect(klass.soft_deleted).to eq([record])
      end

      it "is included in with_soft_deleted scope" do
        expect(klass.with_soft_deleted).to eq([record])
      end

      it "is included in with_soft_deleted.soft_deleted scope" do
        expect(klass.with_soft_deleted.soft_deleted).to eq([record])
      end
    end
  end

  context "with custom column name" do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title
        t.datetime :removed_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true, 
                        column: :removed_at
      end
    end

    context "a kept Post" do
      let!(:post) { Post.create!(title: "My very first post") }

      it "is included in the default scope" do
        expect(Post.all).to eq([post])
      end

      it "is included in kept scope" do
        expect(Post.kept).to eq([post])
      end

      it "is not included in soft_deleted scope" do
        expect(Post.soft_deleted).to eq([])
      end

      it "should not be soft_deleted?" do
        expect(post).not_to be_soft_deleted
      end

      it "should be kept?" do
        expect(post).to be_kept
      end

      describe '#soft_destroy' do
        it "sets deleted_at" do
          expect {
            post.soft_destroy
          }.to change { post.removed_at }
        end

        it "sets deleted_at in DB" do
          expect {
            post.soft_destroy
          }.to change { post.reload.removed_at }
        end
      end

      describe '#soft_delete' do
        it "sets deleted_at" do
          expect {
            post.soft_delete
          }.to change { post.removed_at }
        end

        it "sets deleted_at in DB" do
          expect {
            post.soft_delete
          }.to change { post.reload.removed_at }
        end
      end

      describe '#restore' do
        it "doesn't change deleted_at" do
          expect {
            post.restore
          }.not_to change { post.removed_at }
        end

        it "doesn't change deleted_at in DB" do
          expect {
            post.restore
          }.not_to change { post.reload.removed_at }
        end
      end

      describe '#reconstruct' do
        it "doesn't change deleted_at" do
          expect {
            post.reconstruct
          }.not_to change { post.removed_at }
        end

        it "doesn't change deleted_at in DB" do
          expect {
            post.reconstruct
          }.not_to change { post.reload.removed_at }
        end
      end
    end

    context "soft_deleted Post" do
      let!(:post) { Post.create!(title: "A soft_deleted post", removed_at: Time.parse('2017-01-01')) }

      it "is included in the default scope" do
        expect(Post.all).to eq([post])
      end

      it "is not included in kept scope" do
        expect(Post.kept).to eq([])
      end

      it "is included in soft_deleted scope" do
        expect(Post.soft_deleted).to eq([post])
      end

      it "should be soft_deleted?" do
        expect(post).to be_soft_deleted
      end

      it "should not be kept?" do
        expect(post).to_not be_kept
      end

      describe '#soft_destroy' do
        it "doesn't change deleted_at" do
          expect {
            post.soft_destroy
          }.not_to change { post.removed_at }
        end

        it "doesn't change deleted_at in DB" do
          expect {
            post.soft_destroy
          }.not_to change { post.reload.removed_at }
        end
      end

      describe '#soft_delete' do
        it "doesn't change deleted_at" do
          expect {
            post.soft_delete
          }.not_to change { post.removed_at }
        end

        it "doesn't change deleted_at in DB" do
          expect {
            post.soft_delete
          }.not_to change { post.reload.removed_at }
        end
      end

      describe '#restore' do
        it "clears deleted_at" do
          expect {
            post.restore
          }.to change { post.removed_at }.to(nil)
        end

        it "clears deleted_at in DB" do
          expect {
            post.restore
          }.to change { post.reload.removed_at }.to(nil)
        end
      end

      describe '#reconstruct' do
        it "clears deleted_at" do
          expect {
            post.reconstruct
          }.to change { post.removed_at }.to(nil)
        end

        it "clears deleted_at in DB" do
          expect {
            post.reconstruct
          }.to change { post.reload.removed_at }.to(nil)
        end
      end
    end
  end

  describe '.soft_destroy_all' do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true
      end
    end

    let!(:post) { Post.create!(title: "My very first post") }
    let!(:post2) { Post.create!(title: "A second post") }

    it "can soft_destroy all posts" do
      expect {
        Post.soft_destroy_all
      }.to   change { post.reload.soft_deleted? }.to(true)
        .and change { post2.reload.soft_deleted? }.to(true)
    end

    it "can soft_destroy a single post" do
      Post.where(id: post.id).soft_destroy_all
      expect(post.reload).to be_soft_deleted
      expect(post2.reload).not_to be_soft_deleted
    end

    it "can soft_destroy no records" do
      Post.where(id: []).soft_destroy_all
      expect(post.reload).not_to be_soft_deleted
      expect(post2.reload).not_to be_soft_deleted
    end

    context "through a collection" do
      with_model :Comment, scope: :all do
        table do |t|
          t.belongs_to :user
          t.datetime :deleted_at
          t.timestamps null: false
        end

        model do
          acts_as_deletic without_default_scope: true
        end
      end

      with_model :User, scope: :all do
        table do |t|
          t.timestamps null: false
        end

        model do
          has_many :comments
        end
      end

      it "can be soft_destroy all related posts" do
        user1 = User.create!
        user2 = User.create!

        2.times { user1.comments.create! }
        2.times { user2.comments.create! }

        user1.comments.soft_destroy_all
        user1.comments.each do |comment|
          expect(comment).to be_soft_deleted
          expect(comment).to_not be_kept
        end
        user2.comments.each do |comment|
          expect(comment).to_not be_soft_deleted
          expect(comment).to be_kept
        end
      end
    end
  end

  describe '.soft_destroy_all!' do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true
      end
    end

    let!(:post) { Post.create!(title: "My very first post") }
    let!(:post2) { Post.create!(title: "A second post") }

    it "can soft_destroy all posts" do
      expect {
        Post.soft_destroy_all!
      }.to   change { post.reload.soft_deleted? }.to(true)
        .and change { post2.reload.soft_deleted? }.to(true)
    end
  end

  describe '.soft_delete_all' do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true
      end
    end

    let!(:post) { Post.create!(title: "My very first post") }
    let!(:post2) { Post.create!(title: "A second post") }

    it "can soft_delete all posts" do
      expect {
        Post.soft_delete_all
      }.to   change { post.reload.soft_deleted? }.to(true)
        .and change { post2.reload.soft_deleted? }.to(true)
    end

    it "can soft_delete a single post" do
      Post.where(id: post.id).soft_delete_all
      expect(post.reload).to be_soft_deleted
      expect(post2.reload).not_to be_soft_deleted
    end

    it "can soft_delete no records" do
      Post.where(id: []).soft_delete_all
      expect(post.reload).not_to be_soft_deleted
      expect(post2.reload).not_to be_soft_deleted
    end

    context "through a collection" do
      with_model :Comment, scope: :all do
        table do |t|
          t.belongs_to :user
          t.datetime :deleted_at
          t.timestamps null: false
        end

        model do
          acts_as_deletic without_default_scope: true
        end
      end

      with_model :User, scope: :all do
        table do |t|
          t.timestamps null: false
        end

        model do
          has_many :comments
        end
      end

      it "can be soft_delete all related posts" do
        user1 = User.create!
        user2 = User.create!

        2.times { user1.comments.create! }
        2.times { user2.comments.create! }

        user1.comments.soft_delete_all
        user1.comments.each do |comment|
          expect(comment).to be_soft_deleted
          expect(comment).to_not be_kept
        end
        user2.comments.each do |comment|
          expect(comment).to_not be_soft_deleted
          expect(comment).to be_kept
        end
      end
    end
  end

  describe '.restore_all' do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true
      end
    end

    let!(:post) { Post.create!(title: "My very first post", deleted_at: Time.now) }
    let!(:post2) { Post.create!(title: "A second post", deleted_at: Time.now) }

    it "can restore all posts" do
      expect {
        Post.restore_all
      }.to   change { post.reload.soft_deleted? }.to(false)
        .and change { post2.reload.soft_deleted? }.to(false)
    end

    it "can restore a single post" do
      Post.where(id: post.id).restore_all
      expect(post.reload).not_to be_soft_deleted
      expect(post2.reload).to be_soft_deleted
    end

    it "can restore no records" do
      Post.where(id: []).restore_all
      expect(post.reload).to be_soft_deleted
      expect(post2.reload).to be_soft_deleted
    end
  end

  describe '.restore_all!' do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true
      end
    end

    let!(:post) { Post.create!(title: "My very first post", deleted_at: Time.now) }
    let!(:post2) { Post.create!(title: "A second post", deleted_at: Time.now) }

    it "can restore all posts" do
      expect {
        Post.restore_all!
      }.to   change { post.reload.soft_deleted? }.to(false)
        .and change { post2.reload.soft_deleted? }.to(false)
    end
  end

  describe '.reconstruct_all' do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true
      end
    end

    let!(:post) { Post.create!(title: "My very first post", deleted_at: Time.now) }
    let!(:post2) { Post.create!(title: "A second post", deleted_at: Time.now) }

    it "can restore all posts" do
      expect {
        Post.reconstruct_all
      }.to   change { post.reload.soft_deleted? }.to(false)
        .and change { post2.reload.soft_deleted? }.to(false)
    end

    it "can restore a single post" do
      Post.where(id: post.id).reconstruct_all
      expect(post.reload).not_to be_soft_deleted
      expect(post2.reload).to be_soft_deleted
    end

    it "can restore no records" do
      Post.where(id: []).reconstruct_all
      expect(post.reload).to be_soft_deleted
      expect(post2.reload).to be_soft_deleted
    end
  end

  describe 'soft_destroy callbacks with skip_ar_callbacks=false' do
    with_model :Post, scope: :all do
      table do |t|
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true,
                        skip_ar_callbacks: false

        before_soft_destroy :do_before_soft_destroy
        before_save :do_before_save
        after_save :do_after_save
        after_soft_destroy :do_after_soft_destroy

        def do_before_soft_destroy; end
        def do_before_save; end
        def do_after_save; end
        def do_after_soft_destroy; end
      end
    end

    def abort_callback
      if ActiveRecord::VERSION::MAJOR < 5
        false
      else
        throw :abort
      end
    end

    let!(:post) { Post.create! }

    it "runs callbacks in correct order" do
      expect(post).to receive(:do_before_soft_destroy).ordered
      expect(post).to receive(:do_before_save).ordered
      expect(post).to receive(:do_after_save).ordered
      expect(post).to receive(:do_after_soft_destroy).ordered

      expect(post.soft_destroy).to be true
      expect(post).to be_soft_deleted
    end

    context 'before_soft_destroy' do
      it "can allow soft_destroy" do
        expect(post).to receive(:do_before_soft_destroy).and_return(true)
        expect(post.soft_destroy).to be true
        expect(post).to be_soft_deleted
      end

      it "can prevent soft_destroy" do
        expect(post).to receive(:do_before_soft_destroy) { abort_callback }
        expect(post.soft_destroy).to be false
        expect(post).not_to be_soft_deleted
      end

      describe '#soft_destroy!' do
        it "raises Deletic::RecordNotDeleted" do
          expect(post).to receive(:do_before_soft_destroy) { abort_callback }
          expect {
            post.soft_destroy!
          }.to raise_error(Deletic::RecordNotDeleted)
        end
      end
    end
  end

  describe 'restore callbacks with skip_ar_callbacks=false' do
    with_model :Post, scope: :all do
      table do |t|
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true,
                        skip_ar_callbacks: false

        before_restore :do_before_restore
        before_save :do_before_save
        after_save :do_after_save
        after_restore :do_after_restore

        def do_before_restore; end
        def do_before_save; end
        def do_after_save; end
        def do_after_restore; end
      end
    end

    def abort_callback
      if ActiveRecord::VERSION::MAJOR < 5
        false
      else
        throw :abort
      end
    end

    let!(:post) { Post.create! deleted_at: Time.now }

    it "runs callbacks in correct order" do
      expect(post).to receive(:do_before_restore).ordered
      expect(post).to receive(:do_before_save).ordered
      expect(post).to receive(:do_after_save).ordered
      expect(post).to receive(:do_after_restore).ordered

      expect(post.restore).to be true
      expect(post).not_to be_soft_deleted
    end

    context 'before_restore' do
      it "can allow restore" do
        expect(post).to receive(:do_before_restore).and_return(true)
        expect(post.restore).to be true
        expect(post).not_to be_soft_deleted
      end

      it "can prevent restore" do
        expect(post).to receive(:do_before_restore) { abort_callback }
        expect(post.restore).to be false
        expect(post).to be_soft_deleted
      end

      describe '#restore!' do
        it "raises Deletic::RecordNotDeleted" do
          expect(post).to receive(:do_before_restore) { abort_callback }
          expect {
            post.restore!
          }.to raise_error(Deletic::RecordNotRestored)
        end
      end
    end
  end

  describe 'soft_destroycallbacks with skip_ar_callbacks=true' do
    with_model :Post, scope: :all do
      table do |t|
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true

        before_soft_destroy :do_before_soft_destroy
        before_save :do_before_save
        after_save :do_after_save
        after_soft_destroy :do_after_soft_destroy

        def do_before_soft_destroy; end
        def do_before_save; end
        def do_after_save; end
        def do_after_soft_destroy; end
      end
    end

    def abort_callback
      if ActiveRecord::VERSION::MAJOR < 5
        false
      else
        throw :abort
      end
    end

    let!(:post) { Post.create! }

    it "runs callbacks in correct order" do
      expect(post).to receive(:do_before_soft_destroy).ordered
      expect(post).not_to receive(:do_before_save)
      expect(post).not_to receive(:do_after_save)
      expect(post).to receive(:do_after_soft_destroy).ordered

      expect(post.soft_destroy).to be true
      expect(post).to be_soft_deleted
    end

    context 'before_soft_destroy' do
      it "can allow soft_destroy" do
        expect(post).to receive(:do_before_soft_destroy).and_return(true)
        expect(post.soft_destroy).to be true
        expect(post).to be_soft_deleted
      end

      it "can prevent soft__destroy" do
        expect(post).to receive(:do_before_soft_destroy) { abort_callback }
        expect(post.soft_destroy).to be false
        expect(post).not_to be_soft_deleted
      end

      describe '#soft_destroy!' do
        it "raises Deletic::RecordNotDeleted" do
          expect(post).to receive(:do_before_soft_destroy) { abort_callback }
          expect {
            post.soft_destroy!
          }.to raise_error(Deletic::RecordNotDeleted)
        end
      end
    end
  end

  describe 'restore callbacks with skip_ar_callbacks=true' do
    with_model :Post, scope: :all do
      table do |t|
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        acts_as_deletic without_default_scope: true

        before_restore :do_before_restore
        before_save :do_before_save
        after_save :do_after_save
        after_restore :do_after_restore

        def do_before_restore; end
        def do_before_save; end
        def do_after_save; end
        def do_after_restore; end
      end
    end

    def abort_callback
      if ActiveRecord::VERSION::MAJOR < 5
        false
      else
        throw :abort
      end
    end

    let!(:post) { Post.create! deleted_at: Time.now }

    it "runs callbacks in correct order" do
      expect(post).to receive(:do_before_restore).ordered
      expect(post).not_to receive(:do_before_save)
      expect(post).not_to receive(:do_after_save)
      expect(post).to receive(:do_after_restore).ordered

      expect(post.restore).to be true
      expect(post).not_to be_soft_deleted
    end

    context 'before_restore' do
      it "can allow restore" do
        expect(post).to receive(:do_before_restore).and_return(true)
        expect(post.restore).to be true
        expect(post).not_to be_soft_deleted
      end

      it "can prevent restore" do
        expect(post).to receive(:do_before_restore) { abort_callback }
        expect(post.restore).to be false
        expect(post).to be_soft_deleted
      end

      describe '#restore!' do
        it "raises Deletic::RecordNotDeleted" do
          expect(post).to receive(:do_before_restore) { abort_callback }
          expect {
            post.restore!
          }.to raise_error(Deletic::RecordNotRestored)
        end
      end
    end
  end
end