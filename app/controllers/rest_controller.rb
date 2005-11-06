class RestController < ApplicationController
    rest_resource :project
    rest_resource :revision
    rest_resource :build
end