require 'users_controller.rb'
class IssuesController < ApplicationController
  before_action :set_issue, only: %i[show edit update destroy]
  before_action :authenticate_api_key, only: [:destroy]


  def authenticate_api_key
    # Llama a la función authenticate_api_key del UsersController
    UsersController.new.authenticate_api_key(api_key)
  end

  def index
    @issues = Issue.all


    if params[:filtro].present?
      @filtered_issues = @issues.where("lower(subject) LIKE ? OR lower(description) LIKE ?", "%#{params[:filtro].downcase}%", "%#{params[:filtro].downcase}%")
    elsif params[:options].present?
      options = params[:options].map(&:downcase)
      @filtered_issues = @issues.where("severity IN (?) OR issue_type IN (?) OR priority IN (?) OR assign IN (?) OR status IN (?) OR created_by IN (?)" , options.map(&:capitalize), options.map(&:capitalize), options.map(&:capitalize), options.map(&:titleize), options.map(&:capitalize),options.map(&:titleize))
    else
      @filtered_issues = @issues
    end

    if params[:order_by].present? && params[:direction].present?
      @ordered_issues = @filtered_issues.order("#{params[:order_by]} #{params[:direction]}")
    else
      @ordered_issues = @filtered_issues
    end


    # agregar estas líneas para preservar los parámetros de búsqueda al ordenar
    @params_without_order_by = request.query_parameters.except(:order_by, :direction)
    @order_by_params = { order_by: params[:order_by], direction: params[:direction] }

    @issues = @ordered_issues
  end

def inicial
    @issues = Issue.all
end

  # GET /issues/1 or /issues/1.json
  def show
    @comment = Comment.new
    @issue = Issue.find(params[:id])
    @comments = @issue.comments
    @attachments = Attachment.new
    @watchers = User.where(id: @issue.watcher_ids).pluck(:full_name)
  end

  # GET /issues/new
  def new
    @issue = Issue.new
    @attachment = Attachment.new
  end

  # GET /issues/1/edit
  def edit
    @attachment = Attachment.new
  end

  # POST /issues or /issues.json
  def create
    watcher_ids = params[:issue][:watcher_ids].presence || []
    @issue = Issue.new(issue_params.merge(watcher_ids: watcher_ids))
    Rails.logger.info "issue_params: #{issue_params.inspect}"


    respond_to do |format|
      if @issue.save
        format.html { redirect_to issues_url, notice: "" }
        format.json { render :show, status: :created, location: @issue }
    record_activity(current_user.id, @issue.id, 'created')
    issue_params[:watcher_ids].each do |user|
      IssueWatcher.create(issue_id: @issue.id, user_id: user)
    end


      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end



  def create_multiple_issues
  subjects = params[:subjects].split("\n")
  issues_created = []
  subjects.each do |subject|
    issue = Issue.new(subject: subject.strip, created_by: current_user.full_name, status: 'New')
    if issue.save
      issues_created << issue
    record_activity(current_user.id, issue.id, 'created in bulk')
    end
  end
  redirect_to issues_path
end





  # PATCH/PUT /issues/1 or /issues/1.json
  def update
    respond_to do |format|
      type_antic = @issue.issue_type
      severity_antic = @issue.severity
      priority_antic = @issue.priority
      subject_antic = @issue.subject
      description_antic = @issue.description
      assign_antic = @issue.assign
      status_antic = @issue.status
      watcher_ids_antic = @issue.watcher_ids

      if @issue.update(issue_params)
        format.html { redirect_to issue_url(@issue), notice: "" }
        format.json { render :show, status: :ok, location: @issue }

      if (subject_antic != issue_params[:subject])
        record_activity(current_user.id, @issue.id, "changed subject from #{subject_antic} to #{issue_params[:subject]} of")
      end
      if (description_antic != issue_params[:description])
        record_activity(current_user.id, @issue.id, 'changed description of')
      end
      if (assign_antic != issue_params[:assign])
        if (assign_antic.nil? or assign_antic.empty?)
          assign_antic = "unassigned"
        end
        record_activity(current_user.id, @issue.id, "changed assignation from #{assign_antic} to #{issue_params[:assign]} of")
      end
      if (type_antic != issue_params[:issue_type])
        record_activity(current_user.id, @issue.id, "changed type from #{type_antic} to #{issue_params[:issue_type]} of")
      end
      if (severity_antic != issue_params[:severity])
        record_activity(current_user.id, @issue.id, "changed severity from #{severity_antic} to #{issue_params[:severity]} of")
      end
      if (priority_antic != issue_params[:priority])
        record_activity(current_user.id, @issue.id, "changed priority from #{priority_antic} to #{issue_params[:priority]} of")
      end
      if (status_antic != issue_params[:status])
        record_activity(current_user.id, @issue.id, "changed status from #{status_antic} to #{issue_params[:status]} of")
      end
      if (watcher_ids_antic != issue_params[:watcher_ids])
        record_activity(current_user.id, @issue.id, "changed watchers of")
        #borrar totes les antigues
        @watchs = IssueWatcher.where(issue_id: @issue.id)
        @watchs.each(&:destroy!)
        issue_params[:watcher_ids].each do |user|
          IssueWatcher.create(issue_id: @issue.id, user_id: user)
        end
      end      #record_activity(current_user.id, @issue.id, 'modified')

      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issues/1 or /issues/1.json
  def destroy

    attachments_controller = AttachmentsController.new

  @issue.attachments.each do |attachment|
    attachments_controller.destroy_attachment(attachment)
  end
  # Delete all associated attachments first
  @issue.attachments.destroy_all
  @watchs = IssueWatcher.where(issue_id: @issue.id)
  @watchs.each(&:destroy!)
  @activities = Activity.where(issue_id: @issue.id)
  @activities.each(&:destroy!)

    @issue.destroy
    respond_to do |format|
      format.html { redirect_to issues_url, notice: "" }
      format.json {  render json: { message: "Issue deleted successfully" }, status: :ok  }
    end

  end

  def block
  @issue = Issue.find(params[:id])
  @issue.update(blocked: !@issue.blocked)
      record_activity(current_user.id, @issue.id, @issue.blocked ? 'blocked' : 'unblocked')
  redirect_to @issue
  end
def destroy_single_attachment
      attachment = Attachment.find(params[:id])
      attachments_controller = AttachmentsController.new
      attachments_controller.destroy_attachment(attachment)


      flash[:notice] = "Attachment successfully deleted."
      redirect_to issue_path(attachment.issue)
end

  def add_deadline
  @issue = Issue.find(params[:id])
  if params[:deadline_date].present?
    deadline_date = Date.parse(params[:deadline_date])
    @issue.update(deadline: deadline_date)
    record_activity(current_user.id, @issue.id, "added deadline of #{deadline_date} for")
  end
  redirect_to @issue
  end

  def delete_deadline
    @issue = Issue.find(params[:id])
    @issue.update(deadline: nil)
    record_activity(current_user.id, @issue.id, 'removed deadline for')
    redirect_to @issue
  end


    def record_activity(user, issue, action)
          Activity.create(action: action, issue_id: issue, user_id: user)


    end


  def all_issues_as_json
    @issues = Issue.all
    render json: @issues
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_issue
      @issue = Issue.find(params[:id])
    end
    # Only allow a list of trusted parameters through.
    def issue_params
      params.require(:issue).permit(:subject, :description, :assign, :issue_type, :severity, :priority, :status, :created_by, :watcher_ids => [])
    end

end

