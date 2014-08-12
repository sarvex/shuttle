module Api
  module V1
    class KeyGroupsController < ApplicationController
      respond_to :json

      skip_before_action :verify_authenticity_token
      before_filter :authenticate_and_find_project
      before_filter :find_key_group, only: [:show, :update, :status, :manifest]

      # Returns all KeyGroups in the Project.
      #
      # Routes
      # ------
      #
      # * `GET /key_groups?api_token=:api_token`
      #
      # Path/Url Parameters
      # ---------------
      #
      # |             |                              |
      # |:------------|:-----------------------------|
      # | `api_token` | The api token for a Project. |

      def index
        render json: decorate_key_groups(@project.key_groups)
      end

      # Creates a KeyGroup in a Project.
      #
      # Routes
      # ------
      #
      # * `POST /key_groups?api_token=:api_token`
      #
      # Path/Url Parameters
      # ---------------
      #
      # |             |                              |
      # |:------------|:-----------------------------|
      # | `api_token` | The api token for a Project. |
      #
      # Body Parameters
      # ---------------
      #
      # |                            |                                                                             |
      # |:---------------------------|:----------------------------------------------------------------------------|
      # | `key`                      | The `key` of the KeyGroup.                                                  |
      # | `source_copy`              | The source copy of the KeyGroup                                             |
      # | `description`              | The description of the KeyGroup                                             |
      # | `email`                    | An email address which can be used for communication regarding the KeyGroup |
      # | `base_rfc5646_locale`      | Base rfc5646 locale of the KeyGroup                                         |
      # | `targeted_rfc5646_locales` | Targeted rfc5646 locales for the KeyGroup                                   |

      def create
        key_group = @project.key_groups.create(params_for_create)
        if key_group.errors.blank?
          render json: decorate_key_group(key_group), status: :accepted
        else
          render json: { error: { errors: key_group.errors } }, status: :bad_request
        end
      end

      # Returns a KeyGroup.
      #
      # Routes
      # ------
      #
      # * `GET /key_groups/:key?api_token=:api_token`
      #
      # Path/Url Parameters
      # ---------------
      #
      # |             |                              |
      # |:------------|:-----------------------------|
      # | `api_token` | The api token for a Project. |
      # | `key`       | The `key` of the KeyGroup.   |

      def show
        render json: decorate_key_group(@key_group)
      end

      # Updates a KeyGroup in a Project.
      #
      # Routes
      # ------
      #
      # * `PATCH /key_groups/:key?api_token=:api_token`
      #
      # Path/Url Parameters
      # ---------------
      #
      # |             |                              |
      # |:------------|:-----------------------------|
      # | `api_token` | The api token for a Project. |
      # | `key`       | The `key` of the KeyGroup.   |
      #
      # Body Parameters
      # ---------------
      #
      # |         |                                                                                                |
      # |:--------|:-----------------------------------------------------------------------------------------------|
      # | `source_copy`              | The source copy of the KeyGroup                                             |
      # | `description`              | The description of the KeyGroup                                             |
      # | `email`                    | An email address which can be used for communication regarding the KeyGroup |
      # | `targeted_rfc5646_locales` | Targeted rfc5646 locales for the KeyGroup                                   |

      def update
        @key_group.update(params_for_update)
        if @key_group.errors.blank?
          render json: decorate_key_group(@key_group), status: :accepted
        else
          render json: { error: { errors: @key_group.errors } }, status: :bad_request
        end
      end

      # Returns the status of a KeyGroup.
      #
      # Routes
      # ------
      #
      # * `GET /key_groups/:key/status?api_token=:api_token`
      #
      # Path/Url Parameters
      # ---------------
      #
      # |             |                              |
      # |:------------|:-----------------------------|
      # | `api_token` | The api token for a Project. |
      # | `key`       | The `key` of the KeyGroup.   |

      def status
        render json: decorate_key_group_status(@key_group)
      end

      # Returns the translated copies of a KeyGroup if all translations are finished.
      # Returns the error message, otherwise.
      #
      # Routes
      # ------
      #
      # * `GET /key_groups/:key/manifest?api_token=:api_token`
      #
      # Path/Url Parameters
      # ---------------
      #
      # |             |                              |
      # |:------------|:-----------------------------|
      # | `api_token` | The api token for a Project. |
      # | `key`       | The `key` of the KeyGroup.   |

      def manifest
        begin
          render json: Exporter::KeyGroup.new(@key_group).export
        rescue Exporter::KeyGroup::Error => e
          render json: { error: { errors: [{ message: e.inspect }] } }, status: :bad_request
        end
      end

      private

      # ===== START AUTHENTICATION/AUTHORIZATION/VALIDATION ============================================================
      def authenticate_and_find_project
        unless @project = Project.find_by_api_token(params[:api_token])
          render json: { error: { errors: [{ message: t("controllers.api.v1.key_groups.invalid_api_token") }] } }, status: :unauthorized
        end
      end

      def find_key_group
        unless @key_group = @project.key_groups.find_by_key(params[:key])
          render json: { error: { errors: [{ message: t("controllers.api.v1.key_groups.key_group_not_found") }] } }, status: :not_found
        end
      end
      # ===== END AUTHENTICATION/AUTHORIZATION/VALIDATION ==============================================================

      # ===== START DECORATORS =========================================================================================
      def decorate_key_groups(key_groups)
        key_groups.map do |key_group|
          {
            key: key_group.key,
            ready: key_group.ready
          }
        end
      end

      def decorate_key_group(key_group)
        [
         :key, :project_id, :source_copy, :ready, :loading, :description, :email,
         :base_rfc5646_locale, :targeted_rfc5646_locales,
         :first_import_requested_at, :last_import_requested_at,
         :first_import_started_at, :last_import_started_at,
         :first_import_finished_at, :last_import_finished_at,
         :first_completed_at, :last_completed_at,
         :created_at, :updated_at
        ].inject({}) do |hsh, field|
          hsh[field] = key_group.send(field)
          hsh
        end
      end

      def decorate_key_group_status(key_group)
        {
          ready: key_group.ready,
          last_import_requested_at: key_group.last_import_requested_at,
          last_import_started_at: key_group.last_import_started_at,
          last_import_finished_at: key_group.last_import_finished_at,
          last_completed_at: key_group.last_completed_at
        }
      end
      # ===== END DECORATORS ===========================================================================================

      # ===== START PARAMS RELATED CODE ================================================================================
      def params_for_create
        hsh = params.permit(:key, :source_copy, :description, :email, :base_rfc5646_locale)
        hsh[:targeted_rfc5646_locales] = params[:targeted_rfc5646_locales] if params.key?(:targeted_rfc5646_locales)
        hsh
      end

      def params_for_update
        hsh = params.permit(:source_copy, :description, :email)
        hsh[:targeted_rfc5646_locales] = params[:targeted_rfc5646_locales] if params.key?(:targeted_rfc5646_locales)
        hsh
      end
      # ===== END PARAMS RELATED CODE ==================================================================================
    end
  end
end
