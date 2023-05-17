require 'users_controller.rb'

require 'comments_controller.rb'

class IssuesController < ApplicationController
  before_action :set_issue, only: %i[show edit update destroy]
  before_action -> { authenticate_api_key(request.headers['Authorization'].present?) }, only: [:destroy, :create, :create_comment, :block, :add_deadline, :delete_deadline, :create_multiple_issues]
 rescue_from ActiveRecord::RecordNotFound, with: :issue_not_found


def issue_not_found
    render json: { error: 'Issue not found' }, status: :not_found
end

  def authenticate_api_key(verify_key = true)
  if verify_key
    @authenticated_user = UsersController.new.authenticate_api_key(request)
    if @authenticated_user == :unauthorized
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end


  def index
    if params[:filtro] == "" and params[:options] == "" and params[:order_by] == "" and params[:direction] == ""
      all_issues_as_json
    else
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
    if valid_params_new
    watcher_ids = params[:issue][:watcher_ids].presence || []
    @issue = Issue.new(issue_params.merge(watcher_ids: watcher_ids))
    Rails.logger.info "issue_params: #{issue_params.inspect}"
    puts request.headers['Authorization']

    if current_user
    record_activity(current_user.id, @issue.id, 'created')
    @issue.created_by = current_user.full_name
    else
    record_activity(@authenticated_user.id, @issue.id, 'created')
    @issue.created_by = @authenticated_user.full_name
    end
    issue_params[:watcher_ids].each do |user|
    IssueWatcher.create(issue_id: @issue.id, user_id: user)
    end

    respond_to do |format|
      if @issue.save
        format.html { redirect_to issues_url, notice: "" }
        format.json { render :show, status: :created, location: @issue }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
    end
  end

  def valid_params_new
    ##Este if es para poder crear en la interficie
    if !issue_params[:subject].nil? && !issue_params[:subject].empty?
      return true
    end
    subject = params[:subject]
    if subject.nil? || subject.empty?
      render json: { error: 'The value subject is required.' }, status: :bad_request
      return false
    end
    assign = params[:assign]
    if assign.empty?
      render json: { error: 'The value assign must be the full name of one of the logged users.' }, status: :bad_request
      return false
    end
    if assign.present?
      user = User.find_by(full_name: assign)
      unless user.present?
        render json: { error: 'The value assign must be the full name of one of the logged users.' }, status: :bad_request
        return false
      end
    end
    severity = params[:severity]
    if severity.blank? || !%w[Wishlist Minor Normal Important Critical].include?(severity)
      render json: { error: 'Invalid value severity.' }, status: :bad_request
      return false
    end
    priority = params[:priority]
    if priority.blank? || !%w[Low Normal High].include?(priority)
      render json: { error: 'Invalid value priority.' }, status: :bad_request
      return false
    end
    issue_type = params[:issue_type]
    if issue_type.blank? || !%w[Bug Question Enhancement].include?(issue_type)
      render json: { error: 'Invalid value issue_type.' }, status: :bad_request
      return false
    end
    status_issue = params[:status]
    if status_issue.blank? || !%w[New In\ Progress Ready\ For\ Test Postponed Closed Information\ Needed Rejected].include?(status_issue)
      render json: { error: 'Invalid value status.' }, status: :bad_request
      return false
    end
    return true
  end



  def create_multiple_issues
  puts params[:subjects]
  subjects = params[:subjects].split("\n")
  issues_created = []
  subjects.each do |subject|

  subject.strip! # Eliminar espacios en blanco adicionales al inicio y al final del subject

  next if subject.blank? # Saltar si el subject está vacío después de eliminar los espacios en blanco

    if current_user
      issue = Issue.new(subject: subject.strip, created_by: current_user.full_name, status: 'New')
    else
       issue = Issue.new(subject: subject.strip, created_by: @authenticated_user.full_name, status: 'New')
    end
    if issue.save
      issues_created << issue
    if current_user
      record_activity(current_user.id, issue.id, 'created in bulk')
    else
      record_activity(@authenticated_user.id, issue.id, 'created in bulk')
    end
    end
  end

  if !current_user
  respond_to do |format|
      format.json { render json: { message: "Attachments created successfully" }, status: :ok}
  end
  else
    redirect_to issues_path
  end
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
  if current_user
    record_activity(current_user.id, @issue.id, @issue.blocked ? 'blocked' : 'unblocked')
  else
    record_activity(@authenticated_user.id, @issue.id, @issue.blocked ? 'blocked' : 'unblocked')
  end
  respond_to do |format|
    format.html { redirect_to @issue, notice: "" }
    format.json {  render json: @issue  }
  end
  end


def destroy_single_attachment
      attachment = Attachment.find(params[:id])
      attachments_controller = AttachmentsController.new
      attachments_controller.destroy_attachment(params[:id])

      flash[:notice] = "Attachment successfully deleted."
      redirect_to issue_path(attachment.issue)
end

  #Deadlines

  def add_deadline
  if params[:deadline_date] == ""
    delete_deadline
  else
  @issue = Issue.find(params[:id])
  if params[:deadline_date].present?
    deadline_date = Date.parse(params[:deadline_date])
    if deadline_date < Date.today
      render json: { error: "Deadline must be greater than or equal to today's date" }, status: :unprocessable_entity
    end
    @issue.update(deadline: deadline_date)
    if current_user
      record_activity(current_user.id, @issue.id, "added deadline of #{deadline_date} for")
    else
      record_activity(@authenticated_user.id, @issue.id, "added deadline of #{deadline_date} for")
    end
  end
  respond_to do |format|
    format.html { redirect_to @issue, notice: "" }
    format.json { render json: @issue  }
  end
  end
  end

  def delete_deadline
    @issue = Issue.find(params[:id])
    @issue.update(deadline: nil)
    if current_user
    record_activity(current_user.id, @issue.id, 'removed deadline for')
    else
    record_activity(@authenticated_user.id, @issue.id, 'removed deadline for')
    end

    respond_to do |format|
      format.html { redirect_to @issue, notice: "" }
      format.json { render json: @issue  }
    end
  end



    def record_activity(user, issue, action)
          Activity.create(action: action, issue_id: issue, user_id: user)
    end

  def all_issues_as_json
    @issues = Issue.all
    render json: @issues
  end


  #Comentaris

  def create_comment
    if current_user
     CommentsController.new.create
    else
     puts request.headers['Authorization']
     comments_controller = CommentsController.new
     issue_id = params[:issue_id]
     content = params[:content]
     @issue = Issue.find(issue_id)
     @comment = @issue.comments.new(content: content, user: @authenticated_user)

      respond_to do |format|
      if @comment.save
        format.json { render json: @comment, status: :created }
      else
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
      end
      end
  end

  def get_comments
    issue_id = params[:id]
    @comments = Issue.find(issue_id).comments

  respond_to do |format|
    format.json { render json: @comments }
    end
  end

  def get_activities
    @issue = Issue.find(params[:id])
    @activities = @issue.activities
    respond_to do |format|
    format.json { render json: @activities }
    end
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

    def comment_params
    params.require(:comment).permit(:content)
    end

end

