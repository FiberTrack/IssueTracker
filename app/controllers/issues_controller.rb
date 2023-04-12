class IssuesController < ApplicationController
  before_action :set_issue, only: %i[show edit update destroy]

  def index
    @issues = Issue.all

    if params[:filtro].present?
      @filtered_issues = @issues.where("lower(subject) LIKE ? OR lower(description) LIKE ?", "%#{params[:filtro].downcase}%", "%#{params[:filtro].downcase}%")
    elsif params[:options].present?
      options = params[:options]
      @filtered_issues = @issues.where("severity IN (?) OR issue_type IN (?) OR priority IN (?) OR assign IN (?)", options.map(&:capitalize), options.map(&:capitalize), options.map(&:capitalize), options.map(&:capitalize))
    else
      @filtered_issues = @issues
    end

    if params[:order_by].present? && params[:direction].present?
      @ordered_issues = @filtered_issues.order("#{params[:order_by]} #{params[:direction]}")
    else
      @ordered_issues = @filtered_issues
    end

    #@issues = @ordered_issues.page(params[:page]).per(10)

    # agregar estas líneas para preservar los parámetros de búsqueda al ordenar
    @params_without_order_by = request.query_parameters.except(:order_by, :direction)
    @order_by_params = { order_by: params[:order_by], direction: params[:direction] }
  end

def inicial
    @issues = Issue.all
  end

  # GET /issues/1 or /issues/1.json
  def show
    @comment = Comment.new
    @issue = Issue.find(params[:id])
    @comments = @issue.comments
  end

  # GET /issues/new
  def new
    @issue = Issue.new
    #record_activity(current_user, 'New')
  end

  # GET /issues/1/edit
  def edit
  end

  # POST /issues or /issues.json
  def create
    @issue = Issue.new(issue_params)

    respond_to do |format|
      if @issue.save
        format.html { redirect_to issues_url, notice: "" }
        format.json { render :show, status: :created, location: @issue }
          #record_activity(current_user, 'Create')

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
    issue = Issue.new(subject: subject.strip)
    if issue.save
      issues_created << issue
      #record_activity(current_user, 'Created in bulk')
    end
  end
  redirect_to issues_path
end




  # PATCH/PUT /issues/1 or /issues/1.json
  def update
    respond_to do |format|
      if @issue.update(issue_params)
        format.html { redirect_to issue_url(@issue), notice: "" }
        format.json { render :show, status: :ok, location: @issue }
          #record_activity(current_user, 'updated')

      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issues/1 or /issues/1.json
  def destroy
    @issue.destroy

    respond_to do |format|
      format.html { redirect_to issues_url, notice: "" }
      format.json { head :no_content }
    end
  end

  def block
  @issue = Issue.find(params[:id])
  @issue.update(blocked: !@issue.blocked)
      puts "Inici"
      record_activity(current_user.id, @issue.id, @issue.blocked ? 'blocked' : 'unblocked')
      puts "Fi"
  redirect_to @issue
  end

  def add_deadline
  @issue = Issue.find(params[:id])
  if params[:deadline_date].present?
    deadline_date = Date.parse(params[:deadline_date])
    @issue.update(deadline: deadline_date)
  end
  redirect_to @issue
  end

  def delete_deadline
    @issue = Issue.find(params[:id])
    @issue.update(deadline: nil)
    redirect_to @issue
  end


    def record_activity(user, issue, action)
          puts "Invoked"
          Activity.create(action: action, issue_id: issue, user_id: user)
    #Activity.create(user: user, action: action)
            puts "Done"

    end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_issue
      @issue = Issue.find(params[:id])
    end
    # Only allow a list of trusted parameters through.
    def issue_params
      params.require(:issue).permit(:subject, :description, :assign, :issue_type, :severity, :priority)
    end
end
