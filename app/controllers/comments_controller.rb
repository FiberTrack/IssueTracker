class CommentsController < ApplicationController
  def new
    @issue = Issue.find(params[:issue_id])
    @comment = @issue.comments.build
  end

  def create
    @issue = Issue.find(params[:issue_id])
    @comment = @issue.comments.create(comment_params.merge(user: current_user))
    redirect_to issue_path(@issue)
  end

  def create_api (issue_id, user, content)
    @issue = Issue.find(issue_id)
    @comment = @issue.comments.new(content: content, user: user)

    if @comment.save
      render json: @comment, status: :created
      redirect_to issue_path(@issue)
    else
      render json: @comment.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @issue = Issue.find(params[:issue_id])
    @comment = @issue.comments.find(params[:id])
    @comment.destroy
    redirect_to issue_path(@issue)
  end

  private
    def comment_params
      params.require(:comment).permit(:content,)
    end
end