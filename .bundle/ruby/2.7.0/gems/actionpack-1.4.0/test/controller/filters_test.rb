require File.dirname(__FILE__) + '/../abstract_unit'

class FilterTest < Test::Unit::TestCase
  class TestController < ActionController::Base
    before_filter :ensure_login

    def show
      render_text "ran action"
    end

    private
      def ensure_login
        @ran_filter ||= []
        @ran_filter << "ensure_login"
      end
  end

  class RenderingController < ActionController::Base
    before_filter :render_something_else

    def show
      @ran_action = true
      render_text "ran action"
    end

    private
      def render_something_else
        render_text "something else"
      end
  end
  
  class ConditionalFilterController < ActionController::Base
    def show
      render_text "ran action"
    end

    def another_action
      render_text "ran action"
    end

    def show_without_filter
      render_text "ran action without filter"
    end

    private
      def ensure_login
        @ran_filter ||= []
        @ran_filter << "ensure_login"
      end

      def clean_up_tmp
        @ran_filter ||= []
        @ran_filter << "clean_up_tmp"
      end
      
      def rescue_action(e) raise(e) end
  end

  class ConditionalCollectionFilterController < ConditionalFilterController
    before_filter :ensure_login, :except => [ :show_without_filter, :another_action ]
  end

  class OnlyConditionSymController < ConditionalFilterController 
    before_filter :ensure_login, :only => :show
  end

  class ExceptConditionSymController < ConditionalFilterController
    before_filter :ensure_login, :except => :show_without_filter
  end

  class BeforeAndAfterConditionController < ConditionalFilterController
    before_filter :ensure_login, :only => :show
    after_filter  :clean_up_tmp, :only => :show 
  end
  
  class OnlyConditionProcController < ConditionalFilterController 
    before_filter(:only => :show) {|c| c.assigns["ran_proc_filter"] = true }
  end

  class ExceptConditionProcController < ConditionalFilterController
    before_filter(:except => :show_without_filter) {|c| c.assigns["ran_proc_filter"] = true }
  end

  class ConditionalClassFilter
    def self.filter(controller) controller.assigns["ran_class_filter"] = true end
  end

  class OnlyConditionClassController < ConditionalFilterController
    before_filter ConditionalClassFilter, :only => :show
  end

  class ExceptConditionClassController < ConditionalFilterController
    before_filter ConditionalClassFilter, :except => :show_without_filter
  end

  class AnomolousYetValidConditionController < ConditionalFilterController
    before_filter(ConditionalClassFilter, :ensure_login, Proc.new {|c| c.assigns["ran_proc_filter1"] = true }, :except => :show_without_filter) { |c| c.assigns["ran_proc_filter2"] = true}
  end

  class PrependingController < TestController
    prepend_before_filter :wonderful_life

    private
      def wonderful_life
        @ran_filter ||= []
        @ran_filter << "wonderful_life"
      end
  end

  class ProcController < PrependingController
    before_filter(proc { |c| c.assigns["ran_proc_filter"] = true })
  end

  class ImplicitProcController < PrependingController
    before_filter { |c| c.assigns["ran_proc_filter"] = true }
  end

  class AuditFilter
    def self.filter(controller)
      controller.assigns["was_audited"] = true
    end
  end
  
  class AroundFilter
    def before(controller)
      @execution_log = "before"
      controller.class.execution_log << " before aroundfilter " if controller.respond_to? :execution_log
      controller.assigns["before_ran"] = true
    end

    def after(controller)
      controller.assigns["execution_log"] = @execution_log + " and after"
      controller.assigns["after_ran"] = true
      controller.class.execution_log << " after aroundfilter " if controller.respond_to? :execution_log
    end    
  end

  class AppendedAroundFilter
    def before(controller)
      controller.class.execution_log << " before appended aroundfilter "
    end

    def after(controller)
      controller.class.execution_log << " after appended aroundfilter "
    end    
  end  
  
  class AuditController < ActionController::Base
    before_filter(AuditFilter)
    
    def show
      render_text "hello"
    end
  end

  class BadFilterController < ActionController::Base
    before_filter 2
    
    def show() "show" end
    
    protected
      def rescue_action(e) raise(e) end
  end

  class AroundFilterController < PrependingController
    around_filter AroundFilter.new
  end

  class MixedFilterController < PrependingController
    cattr_accessor :execution_log
    def initialize
      @@execution_log = ""
    end

    before_filter { |c| c.class.execution_log << " before procfilter "  }
    prepend_around_filter AroundFilter.new

    after_filter  { |c| c.class.execution_log << " after procfilter " }
    append_around_filter AppendedAroundFilter.new
  end
  

  def test_added_filter_to_inheritance_graph
    assert_equal [ :fire_flash, :ensure_login ], TestController.before_filters
  end

  def test_base_class_in_isolation
    assert_equal [ :fire_flash ], ActionController::Base.before_filters
  end
  
  def test_prepending_filter
    assert_equal [ :wonderful_life, :fire_flash, :ensure_login ], PrependingController.before_filters
  end
  
  def test_running_filters
    assert_equal %w( wonderful_life ensure_login ), test_process(PrependingController).template.assigns["ran_filter"]
  end

  def test_running_filters_with_proc
    assert test_process(ProcController).template.assigns["ran_proc_filter"]
  end
  
  def test_running_filters_with_implicit_proc
    assert test_process(ImplicitProcController).template.assigns["ran_proc_filter"]
  end
  
  def test_running_filters_with_class
    assert test_process(AuditController).template.assigns["was_audited"]
  end

  def test_running_anomolous_yet_valid_condition_filters
    response = test_process(AnomolousYetValidConditionController)
    assert_equal %w( ensure_login ), response.template.assigns["ran_filter"]
    assert response.template.assigns["ran_class_filter"]
    assert response.template.assigns["ran_proc_filter1"]
    assert response.template.assigns["ran_proc_filter2"]
    
    response = test_process(AnomolousYetValidConditionController, "show_without_filter")
    assert_equal nil, response.template.assigns["ran_filter"]
    assert !response.template.assigns["ran_class_filter"]
    assert !response.template.assigns["ran_proc_filter1"]
    assert !response.template.assigns["ran_proc_filter2"]
  end

  def test_running_collection_condition_filters
    assert_equal %w( ensure_login ), test_process(ConditionalCollectionFilterController).template.assigns["ran_filter"]
    assert_equal nil, test_process(ConditionalCollectionFilterController, "show_without_filter").template.assigns["ran_filter"]
    assert_equal nil, test_process(ConditionalCollectionFilterController, "another_action").template.assigns["ran_filter"]
  end

  def test_running_only_condition_filters
    assert_equal %w( ensure_login ), test_process(OnlyConditionSymController).template.assigns["ran_filter"]
    assert_equal nil, test_process(OnlyConditionSymController, "show_without_filter").template.assigns["ran_filter"]

    assert test_process(OnlyConditionProcController).template.assigns["ran_proc_filter"]
    assert !test_process(OnlyConditionProcController, "show_without_filter").template.assigns["ran_proc_filter"]

    assert test_process(OnlyConditionClassController).template.assigns["ran_class_filter"]
    assert !test_process(OnlyConditionClassController, "show_without_filter").template.assigns["ran_class_filter"]
  end

  def test_running_except_condition_filters
    assert_equal %w( ensure_login ), test_process(ExceptConditionSymController).template.assigns["ran_filter"]
    assert_equal nil, test_process(ExceptConditionSymController, "show_without_filter").template.assigns["ran_filter"]

    assert test_process(ExceptConditionProcController).template.assigns["ran_proc_filter"]
    assert !test_process(ExceptConditionProcController, "show_without_filter").template.assigns["ran_proc_filter"]

    assert test_process(ExceptConditionClassController).template.assigns["ran_class_filter"]
    assert !test_process(ExceptConditionClassController, "show_without_filter").template.assigns["ran_class_filter"]
  end

  def test_running_before_and_after_condition_filters
    assert_equal %w( ensure_login clean_up_tmp), test_process(BeforeAndAfterConditionController).template.assigns["ran_filter"]
    assert_equal nil, test_process(BeforeAndAfterConditionController, "show_without_filter").template.assigns["ran_filter"]
  end
  
  def test_bad_filter
    assert_raises(ActionController::ActionControllerError) { 
      test_process(BadFilterController)
    }
  end
  
  def test_around_filter
    controller = test_process(AroundFilterController)
    assert controller.template.assigns["before_ran"]
    assert controller.template.assigns["after_ran"]
  end
 
  def test_having_properties_in_around_filter
    controller = test_process(AroundFilterController)
    assert_equal "before and after", controller.template.assigns["execution_log"]
  end

  def test_prepending_and_appending_around_filter
    controller = test_process(MixedFilterController)
    assert_equal " before aroundfilter  before procfilter  before appended aroundfilter " +
                 " after appended aroundfilter  after aroundfilter  after procfilter ", 
                 MixedFilterController.execution_log
  end
  
  def test_rendering_breaks_filtering_chain
    response = test_process(RenderingController)
    assert_equal "something else", response.body
    assert !response.template.assigns["ran_action"]
  end

  private
    def test_process(controller, action = "show")
      request = ActionController::TestRequest.new
      request.action = action
      controller.process(request, ActionController::TestResponse.new)
    end
end
