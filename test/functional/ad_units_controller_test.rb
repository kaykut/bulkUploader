require 'test_helper'

class AdUnitsControllerTest < ActionController::TestCase
  setup do
    @ad_unit = ad_units(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:ad_units)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create ad_unit" do
    assert_difference('AdUnit.count') do
      post :create, ad_unit: @ad_unit.attributes
    end

    assert_redirected_to ad_unit_path(assigns(:ad_unit))
  end

  test "should show ad_unit" do
    get :show, id: @ad_unit.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @ad_unit.to_param
    assert_response :success
  end

  test "should update ad_unit" do
    put :update, id: @ad_unit.to_param, ad_unit: @ad_unit.attributes
    assert_redirected_to ad_unit_path(assigns(:ad_unit))
  end

  test "should destroy ad_unit" do
    assert_difference('AdUnit.count', -1) do
      delete :destroy, id: @ad_unit.to_param
    end

    assert_redirected_to ad_units_path
  end
end
