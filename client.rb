class Client
    require "digest/sha1"
    require "cgi"
    require "json"
    require "base64"
    require "openssl"
    require "net/http"
    require "net/https"

    attr_accessor :consumer_key, :consumer_secret, :api_url, :is_ssl

    API_ENDPOINT = "wc-api/v1/"
    HTTP_GET = "GET"
    HTTP_POST = "POST"

    def initialize(consumer_key, consumer_secret, store_url, is_ssl = true)
        if consumer_key && consumer_secret && store_url
            @consumer_key = consumer_key
            @consumer_secret = consumer_secret
            @api_url = store_url + API_ENDPOINT
            @is_ssl = is_ssl
        elsif !consumer_key
            raise "Consumer key missing"
        elsif !consumer_secret
            raise "Consumer secret missing"
        else
            raise "Store URL missing"
        end
    end

    def get_index()
       return make_api_call() 
    end

    def get_orders(params = {})
        return make_api_call("orders", params)
    end

    def get_order(order_id)
        return make_api_call("orders/#{order_id}")
    end

    def get_orders_count()
        return make_api_call("orders/count")
    end

    def get_order_notes(order_id)
        return make_api_call("orders/#{order_id}/notes")
    end

    def update_order(order_id, params = {})
        return make_api_call("orders/#{order_id}", params, 'POST')
    end

    def get_coupons(params = {})
        return make_api_call("coupons", params)
    end

    def get_coupon(coupon_id)
       return make_api_call("coupons/#{coupon_id}")
    end

    def get_coupons_count()
        return make_api_call("coupons/count")
    end

    def get_coupon_by_code(coupon_code)
        return make_api_call("coupons/code/#{coupon_code}") 
    end

    def get_customers(params = {})
        return make_api_call("customers", params)
    end

    def get_customer(customer_id)
        return make_api_call("customers/#{customer_id}")
    end
    
    def get_customer_by_email(email)
        return make_api_call("customers/email/#{email}")
    end

    def get_customers_count()
        return make_api_call("customers/count")
    end

    def get_customer_orders(customer_id)
        return make_api_call("customers/#{customer_id}/orders")
    end

    def get_products()
        return make_api_call("products")
    end

    def get_product(product_id)
        return make_api_call("products/#{product_id}")
    end

    def get_products_count()
        return make_api_call("products/count")
    end

    def get_reports(params = {})
        return make_api_call("reports")
    end

    def get_sales_report(params = {})
        return make_api_call("reports/sales", params)
    end

    def get_top_sellers_report(params = {})
        return make_api_call("reports/sales/top_sellers", params)
    end

    def make_api_call(endpoint, params = {}, method='GET')
        if (!@is_ssl)
            params[:oauth_consumer_key] = @consumer_key
            params[:oauth_nonce] = Digest::SHA1.hexdigest(Time.new.to_i)
            params[:oauth_signature_method] = 'HMAC-256'
            params[:oauth_timestamp] = Time.new.to_i
            params[:oauth_signature] = generate_oauth_signature(endpoint, params, method)
        end

        if (method == HTTP_GET)
            query = URI.encode_www_form(params)
            uri = URI(@api_url + endpoint + '?' + query)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            req = Net::HTTP::Get.new(uri.request_uri)
            req.basic_auth(@consumer_key, @consumer_secret)
            res = http.start { |test| test.request(req) }
        elsif (method == HTTP_POST)
            url = URI.parse(@api_url + endpoint)
            req = Net::HTTP::Post.new(url.path)
            req.basic_auth(@consumer_key, @consumer_secret)
            req.body = params.to_json
            sock = Net::HTTP.new(url.host, url.port)
            sock.use_ssl = true
            res = sock.start { |test| test.request(req) }
        else
            raise "Unsupported HTTP operation requested"    
        end

        return res.body.to_json()
    end

    def generate_oauth_signature(endpoint, params, method)
        base_request_uri = CGI::escape(@api_url + endpoint)

        query_params = []
        params.each { |key, value| query_params.push(CGI::escape(key) + "%3D" + CGI::escape(value)) }

        query_string = "%26".join(query_params)

        string_to_sign = method + "&" + base_request_uri + '&' + query_string

        return Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), @consumer_secret, string_to_sign))
    end
end
