require 'net/http'
require 'minitest/autorun'
require 'json'

describe 'start up' do
  def with_http
    Net::HTTP.start("localhost", 3000) do |http|
      def http.get(path)
        req = Net::HTTP::Get.new path
        self.request req
      end

      def http.post(path, form_data = nil)
        req = Net::HTTP::Post.new path
        req.set_form_data form_data if form_data
        self.request req
      end

      def http.delete(path)
        req = Net::HTTP::Delete.new path
        self.request req
      end

      def http.put(path, form_data = nil)
        req = Net::HTTP::Put.new path
        req.set_form_data form_data if form_data
        self.request req
      end

      yield http 
    end
  end

  it 'should respond 200 with /_' do
    with_http do |http|
      rsp = http.get "/_"
      assert_equal "200", rsp.code
    end
  end

  it 'should be able to add resource' do
    with_http do |http|
      rsp = http.post("/_", "resource" => "users")
      assert_equal "201", rsp.code

      rsp = http.get "/_" 
      assert_equal %w[users], JSON.parse(rsp.body)
    end
  end

  it 'should be able to delete resource' do
    with_http do |http|
      rsp = http.post("/_", "resource" => "users")
      rsp = http.delete("/_/users")
      assert_equal "200", rsp.code
      
      rsp = http.get("/_")
      resources = JSON.parse(rsp.body)
      refute_includes(resources, "users")
    end
  end
  describe 'dynamic resource users' do
    before do
      with_http do |http|
        http.post("/_", "resource" => "users")
      end
    end

    def create_user(http, content)
      rsp = http.post('/users', "content"=> content.to_json)
      [rsp.code, rsp.body]
    end

    def update_user(http, name, content)
      http.put("/users/#{name}", "content" => content.to_json)
    end

    def get_users(http)
      rsp = http.get('/users')
      JSON.parse(rsp.body)
    end

    def get_user(http, id)
      rsp = http.get("/users/#{id}")
      JSON.parse(rsp.body)
    end

    it 'should respond with GET /users' do
      with_http do |http|
        rsp = http.get("/users")
        
        assert_equal "200", rsp.code
      end
    end

    it 'should be able to create user' do
      with_http do |http|
        code, id = create_user(http, {"name" => "Zhangsan", "age" => 21}) 

        assert_equal "201", code
        refute_nil id

        users = get_users(http)
        assert_includes(users, {"name" => "Zhangsan", "age" => 21})
      end
    end

    it 'should be able to update user' do
      with_http do |http|
        zhangsan = {"name" => "Zhangsan", "age" => 21}
        zhangsan1 = {"name" => "Zhangsan1", "age" => 22}
        code_id = create_user(http, zhangsan) 
        update_user(http, code_id[1], zhangsan1) 
        
        users = get_users(http)
        assert_includes(users, zhangsan1)
      end
    end

    it 'should be able to destroy user' do
      with_http do |http|
        zhangsan = {"name" => "Zhangsan", "age" => 21}
        code_id = create_user(http, zhangsan)

        http.delete("/users/#{code_id[1]}")

        users = get_users(http)
        refute_includes(users, zhangsan)
      end
    end

    it 'should be able to show user' do
      with_http do |http|
        zhangsan = {"name" => "Zhangsan", "age" => 21}
        code_id = create_user(http, zhangsan)

        user = get_user(http, code_id[1])

        assert_equal zhangsan, user
      end
    end
  end
end

