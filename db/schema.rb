# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_04_11_165439) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "accounts", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "uid"
    t.string "username"
    t.string "oauth_token"
    t.string "oauth_secret"
    t.datetime "oauth_expires"
    t.string "provider"
    t.string "oauth_refresh_token"
    t.index ["oauth_expires"], name: "index_accounts_on_oauth_expires"
    t.index ["uid", "provider"], name: "index_accounts_on_uid_and_provider", unique: true
    t.index ["uid"], name: "index_accounts_on_uid"
    t.index ["user_id"], name: "index_accounts_on_user_id"
    t.index ["username", "provider"], name: "index_accounts_on_username_and_provider", unique: true
    t.index ["username"], name: "index_accounts_on_username"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "service_name"
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_cache_items", force: :cascade do |t|
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_active_storage_cache_items_on_key"
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.index ["slug"], name: "index_categories_on_slug"
  end

  create_table "ccla_signatures", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
    t.integer "ccla_id"
    t.datetime "signed_at"
    t.string "prefix"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "suffix"
    t.string "email"
    t.string "phone"
    t.string "company"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["ccla_id"], name: "index_ccla_signatures_on_ccla_id"
    t.index ["organization_id"], name: "index_ccla_signatures_on_organization_id"
    t.index ["user_id"], name: "index_ccla_signatures_on_user_id"
  end

  create_table "cclas", id: :serial, force: :cascade do |t|
    t.string "version"
    t.text "head"
    t.text "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["version"], name: "index_cclas_on_version"
  end

  create_table "cla_reports", id: :serial, force: :cascade do |t|
    t.integer "first_ccla_id"
    t.integer "last_ccla_id"
    t.integer "first_icla_id"
    t.integer "last_icla_id"
    t.string "csv_file_name"
    t.string "csv_content_type"
    t.integer "csv_file_size"
    t.datetime "csv_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "collaborators", id: :serial, force: :cascade do |t|
    t.integer "resourceable_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "resourceable_type"
    t.index ["user_id", "resourceable_type", "resourceable_id"], name: "index_cookbook_collaborators_on_user_id_and_resourceable", unique: true
  end

  create_table "commit_shas", id: :serial, force: :cascade do |t|
    t.string "sha", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["sha"], name: "index_commit_shas_on_sha", unique: true
  end

  create_table "contributor_request_responses", id: :serial, force: :cascade do |t|
    t.integer "contributor_request_id", null: false
    t.string "decision", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["contributor_request_id"], name: "index_contributor_request_responses_on_contributor_request_id", unique: true
  end

  create_table "contributor_requests", id: :serial, force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "ccla_signature_id", null: false
    t.index ["organization_id", "user_id"], name: "index_contributor_requests_on_organization_id_and_user_id", unique: true
  end

  create_table "contributors", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
    t.boolean "admin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["organization_id"], name: "index_contributors_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_contributors_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_contributors_on_user_id"
  end

  create_table "curry_commit_authors", id: :serial, force: :cascade do |t|
    t.string "login"
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "authorized_to_contribute", default: false, null: false
    t.index ["email"], name: "index_curry_commit_authors_on_email", unique: true
    t.index ["login"], name: "index_curry_commit_authors_on_login", unique: true
  end

  create_table "curry_pull_request_comments", id: :serial, force: :cascade do |t|
    t.integer "github_id", null: false
    t.integer "pull_request_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "unauthorized_commit_authors", default: [], array: true
    t.index ["github_id"], name: "index_curry_pull_request_comments_on_github_id", unique: true
    t.index ["pull_request_id"], name: "index_curry_pull_request_comments_on_pull_request_id"
  end

  create_table "curry_pull_request_commit_authors", id: :serial, force: :cascade do |t|
    t.integer "pull_request_id", null: false
    t.integer "commit_author_id", null: false
    t.index ["commit_author_id", "pull_request_id"], name: "curry_pr_commit_author_ids", unique: true
    t.index ["commit_author_id"], name: "idx_cuprc_unknown_committer_id"
    t.index ["pull_request_id"], name: "idx_cuprc_pull_request_id"
  end

  create_table "curry_pull_request_updates", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "action"
    t.integer "pull_request_id", null: false
  end

  create_table "curry_pull_requests", id: :serial, force: :cascade do |t|
    t.string "number", null: false
    t.integer "repository_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["number", "repository_id"], name: "index_curry_pull_requests_on_number_and_repository_id", unique: true
    t.index ["repository_id"], name: "index_curry_pull_requests_on_repository_id"
  end

  create_table "curry_repositories", id: :serial, force: :cascade do |t|
    t.string "owner", null: false
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "callback_url", null: false
  end

  create_table "daily_metrics", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.integer "count", default: 0, null: false
    t.date "day", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["key", "day"], name: "index_daily_metrics_on_key_and_day"
  end

  create_table "email_preferences", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "system_email_id", null: false
    t.string "token", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["token"], name: "index_email_preferences_on_token", unique: true
    t.index ["user_id", "system_email_id"], name: "index_email_preferences_on_user_id_and_system_email_id", unique: true
  end

  create_table "extension_dependencies", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "version_constraint", default: ">= 0.0.0", null: false
    t.integer "extension_version_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "extension_id"
    t.index ["extension_id"], name: "index_extension_dependencies_on_extension_id"
    t.index ["extension_version_id", "name", "version_constraint"], name: "cookbook_dependencies_unique_by_name_and_constraint", unique: true
    t.index ["extension_version_id"], name: "index_extension_dependencies_on_extension_version_id"
  end

  create_table "extension_followers", id: :serial, force: :cascade do |t|
    t.integer "extension_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["extension_id", "user_id"], name: "index_extension_followers_on_extension_id_and_user_id", unique: true
  end

  create_table "extension_version_content_items", id: :serial, force: :cascade do |t|
    t.integer "extension_version_id", null: false
    t.string "name", null: false
    t.string "path", null: false
    t.string "item_type", null: false
    t.string "github_url", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["extension_version_id", "path"], name: "evcis_evid_path", unique: true
    t.index ["extension_version_id"], name: "index_extension_version_content_items_on_extension_version_id"
  end

  create_table "extension_version_platforms", id: :serial, force: :cascade do |t|
    t.integer "extension_version_id"
    t.integer "supported_platform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["extension_version_id", "supported_platform_id"], name: "index_cvp_on_cvi_and_spi", unique: true
  end

  create_table "extension_versions", id: :serial, force: :cascade do |t|
    t.integer "extension_id"
    t.string "license"
    t.string "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "tarball_file_name"
    t.string "tarball_content_type"
    t.integer "tarball_file_size"
    t.datetime "tarball_updated_at"
    t.text "readme", default: "", null: false
    t.string "readme_extension", default: "", null: false
    t.boolean "dependencies_imported", default: false
    t.text "description"
    t.integer "legacy_id"
    t.integer "web_download_count", default: 0
    t.integer "api_download_count", default: 0
    t.text "changelog"
    t.string "changelog_extension", default: "", null: false
    t.boolean "foodcritic_failure"
    t.text "foodcritic_feedback"
    t.integer "rb_line_count", default: 0, null: false
    t.integer "yml_line_count", default: 0, null: false
    t.string "last_commit_string"
    t.datetime "last_commit_at"
    t.string "last_commit_sha"
    t.string "last_commit_url"
    t.integer "commit_count", default: 0, null: false
    t.text "release_notes"
    t.jsonb "config", default: {}
    t.string "compilation_error"
    t.index ["config"], name: "index_extension_versions_on_config", using: :gin
    t.index ["legacy_id"], name: "index_extension_versions_on_legacy_id", unique: true
    t.index ["version", "extension_id"], name: "index_extension_versions_on_version_and_extension_id", unique: true
    t.index ["version"], name: "index_extension_versions_on_version"
  end

  create_table "extensions", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "source_url"
    t.boolean "deprecated", default: false
    t.integer "category_id"
    t.string "lowercase_name"
    t.string "issues_url"
    t.integer "extension_followers_count", default: 0
    t.integer "user_id"
    t.integer "replacement_id"
    t.integer "web_download_count", default: 0
    t.integer "api_download_count", default: 0
    t.boolean "featured", default: false
    t.boolean "up_for_adoption"
    t.boolean "privacy"
    t.string "description"
    t.string "github_url"
    t.string "license_name", default: ""
    t.text "license_text", default: ""
    t.boolean "enabled", default: true, null: false
    t.integer "github_organization_id"
    t.string "owner_name"
    t.bigint "tier_id"
    t.index ["enabled"], name: "index_extensions_on_enabled"
    t.index ["github_organization_id"], name: "index_extensions_on_github_organization_id"
    t.index ["name"], name: "index_extensions_on_name"
    t.index ["owner_name", "lowercase_name"], name: "index_extensions_on_owner_name_and_lowercase_name", unique: true
    t.index ["owner_name"], name: "index_extensions_on_owner_name"
    t.index ["tier_id"], name: "index_extensions_on_tier_id"
    t.index ["user_id"], name: "index_extensions_on_user_id"
  end

  create_table "github_organizations", id: :serial, force: :cascade do |t|
    t.integer "github_id", null: false
    t.string "name", null: false
    t.string "avatar_url", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hits", id: :serial, force: :cascade do |t|
    t.string "label", null: false
    t.integer "total", default: 0, null: false
    t.index ["label"], name: "index_hits_on_label", unique: true
  end

  create_table "icla_signatures", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.datetime "signed_at"
    t.string "prefix"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "suffix"
    t.string "email"
    t.string "phone"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.integer "icla_id"
    t.index ["icla_id"], name: "index_icla_signatures_on_icla_id"
    t.index ["user_id"], name: "index_icla_signatures_on_user_id"
  end

  create_table "iclas", id: :serial, force: :cascade do |t|
    t.string "version"
    t.text "head"
    t.text "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["version"], name: "index_iclas_on_version"
  end

  create_table "invitations", id: :serial, force: :cascade do |t|
    t.integer "organization_id"
    t.string "email"
    t.string "token"
    t.boolean "admin"
    t.boolean "accepted"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ownership_transfer_requests", id: :serial, force: :cascade do |t|
    t.integer "extension_id", null: false
    t.integer "recipient_id", null: false
    t.integer "sender_id", null: false
    t.string "token", null: false
    t.boolean "accepted"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["extension_id"], name: "index_ownership_transfer_requests_on_extension_id"
    t.index ["recipient_id"], name: "index_ownership_transfer_requests_on_recipient_id"
    t.index ["token"], name: "index_ownership_transfer_requests_on_token", unique: true
  end

  create_table "release_assets", force: :cascade do |t|
    t.bigint "extension_version_id"
    t.string "platform"
    t.string "arch"
    t.boolean "viable"
    t.string "commit_sha"
    t.datetime "commit_at"
    t.string "github_asset_sha"
    t.string "github_asset_url"
    t.string "github_sha_filename"
    t.string "github_base_filename"
    t.string "github_asset_filename"
    t.string "s3_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "s3_last_modified"
    t.index ["arch"], name: "index_release_assets_on_arch"
    t.index ["commit_sha"], name: "index_release_assets_on_commit_sha"
    t.index ["extension_version_id"], name: "index_release_assets_on_extension_version_id"
    t.index ["platform"], name: "index_release_assets_on_platform"
  end

  create_table "supported_platforms", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "released_on", null: false
  end

  create_table "system_emails", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.string "taggable_type"
    t.integer "taggable_id"
    t.integer "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "tag_id"], name: "index_taggings_on_taggable_id_and_taggable_type_and_tag_id", unique: true
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "tiers", force: :cascade do |t|
    t.string "name"
    t.integer "rank"
    t.string "icon_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rank"], name: "index_tiers_on_rank"
  end

  create_table "tools", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "type"
    t.text "description"
    t.string "source_url"
    t.text "instructions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "lowercase_name"
    t.string "slug"
    t.boolean "up_for_adoption"
    t.index ["lowercase_name"], name: "index_tools_on_lowercase_name", unique: true
    t.index ["slug"], name: "index_tools_on_slug", unique: true
    t.index ["user_id"], name: "index_tools_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "company"
    t.integer "roles_mask"
    t.string "email", default: ""
    t.string "jira_username"
    t.string "irc_nickname"
    t.string "twitter_username"
    t.text "public_key"
    t.string "install_preference"
    t.string "auth_scope", default: "", null: false
    t.string "avatar_url"
    t.boolean "enabled", default: true, null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["roles_mask"], name: "index_users_on_roles_mask"
  end

  add_foreign_key "extensions", "tiers"
end
