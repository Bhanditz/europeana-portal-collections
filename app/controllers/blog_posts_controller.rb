# frozen_string_literal: true
##
# Handles listing and display of blog posts retrieved from Europeana Pro via
# JSON API.
#
# @todo Exception handling when `JsonApiClient` requests fail
# @todo Extract pagination into a controller concern
class BlogPostsController < ApplicationController
  include HomepageHeroImage

  def index
    @pagination_page = blog_posts_page
    @pagination_per = blog_posts_per
    @blog_posts = pro_blog_posts.page(@pagination_page).per(@pagination_per).all
    @hero_image = homepage_hero_image
  end

  def show
    @blog_post = pro_blog_posts.where(slug: params[:slug]).first
  end

  protected

  def pro_blog_posts
    Pro::BlogPost.includes(:network, :persons)
  end

  def blog_posts_page
    (params[:page] || 1).to_i
  end

  def blog_posts_per
    (params[:per_page] || 6).to_i
  end
end