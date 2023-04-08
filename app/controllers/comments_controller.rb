class CommentsController < ApplicationController
  def create
    @issue = Issue.find(params[:issue_id])
    @comment = @issue.comments.create(comment_params)
    redirect_to issue_path(@issue)
  end

  private
    def comment_params
      params.require(:comment).permit(:content)
    end
end
