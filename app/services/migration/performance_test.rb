module Migration
  class PerformanceTest
    attr_reader :endpoints_file_path, :results

    def initialize(endpoints_file_path: "config/parity_check_endpoints.yml")
      @endpoints_file_path = endpoints_file_path
      @results = {}
    end

    def run
      # TODO: run for all providers
      lead_providers[0...1].each(&method(:call_endpoints))
    end

    def generate_spreadsheet
      Axlsx::Package.new do |p|
        workbook = p.workbook
        green = workbook.styles.add_style(bg_color: "FF428751", type: :dxf)
        red = workbook.styles.add_style(bg_color: "FFFF4141", type: :dxf)

        results.each do |lead_provider, methods|
          methods.each do |method, paths|
            workbook.add_worksheet(name: "#{short_name(lead_provider)} - #{method.upcase}") do |sheet|
              # Latency line chart
              sheet.add_row ["Latency", "ECF Avg", "NPQ Avg", "ECF Max", "NPQ Max"]

              paths.each do |path, results|
                sheet.add_row [path, results[:ecf][:latency][:avg], results[:npq][:latency][:avg], results[:ecf][:latency][:max], results[:npq][:latency][:max]]
              end

              row_start = 1
              row_end = row_start + paths.count

              sheet.add_conditional_formatting(
                "C#{row_start + 1}:C#{row_end}",
                type: :cellIs,
                operator: :lessThan,
                formula: "B#{row_start + 1}",
                dxfId: green,
                priority: 1,
              )

              sheet.add_conditional_formatting(
                "C#{row_start + 1}:C#{row_end}",
                type: :cellIs,
                operator: :greaterThan,
                formula: "B#{row_start + 1}",
                dxfId: red,
                priority: 1,
              )

              sheet.add_chart(Axlsx::LineChart, start_at: "#{integer_to_excel_column(7)}1", end_at: "#{integer_to_excel_column(7 + paths.size)}40", title: sheet["A#{row_start}"]) do |chart|
                chart.add_series data: sheet["B#{row_start + 1}:B#{row_end}"], labels: sheet["A#{row_start + 1}:A#{row_end}"], title: sheet["B#{row_start}"], color: "0000FF"
                chart.add_series data: sheet["C#{row_start + 1}:C#{row_end}"], labels: sheet["A#{row_start + 1}:A#{row_end}"], title: sheet["C#{row_start}"], color: "FF0000"

                chart.add_series data: sheet["D#{row_start + 1}:D#{row_end}"], labels: sheet["A#{row_start + 1}:A#{row_end}"], title: sheet["D#{row_start}"], color: "0000FF"
                chart.add_series data: sheet["E#{row_start + 1}:E#{row_end}"], labels: sheet["A#{row_start + 1}:A#{row_end}"], title: sheet["E#{row_start}"], color: "FF0000"

                chart.catAxis.label_rotation = -45
              end

              sheet.add_row [""]

              # Request/second line chart
              sheet.add_row ["Requests/second", "ECF", "NPQ"]

              paths.each do |path, results|
                sheet.add_row [path, results[:ecf][:request][:per_second], results[:npq][:request][:per_second]]
              end

              row_start = row_end + 2
              row_end = row_start + paths.count

              sheet.add_conditional_formatting(
                "C#{row_start + 1}:C#{row_end}",
                type: :cellIs,
                operator: :greaterThan,
                formula: "B#{row_start + 1}",
                dxfId: green,
                priority: 1,
              )

              sheet.add_conditional_formatting(
                "C#{row_start + 1}:C#{row_end}",
                type: :cellIs,
                operator: :lessThan,
                formula: "B#{row_start + 1}",
                dxfId: red,
                priority: 1,
              )

              sheet.add_chart(Axlsx::LineChart, start_at: "#{integer_to_excel_column(7)}42", end_at: "#{integer_to_excel_column(7 + paths.size)}82", title: sheet["A#{row_start}"]) do |chart|
                chart.add_series data: sheet["B#{row_start + 1}:B#{row_end}"], labels: sheet["A#{row_start + 1}:A#{row_end}"], title: sheet["B#{row_start}"], color: "0000FF"
                chart.add_series data: sheet["C#{row_start + 1}:C#{row_end}"], labels: sheet["A#{row_start + 1}:A#{row_end}"], title: sheet["C#{row_start}"], color: "FF0000"
              end

              sheet.add_row [""]

              # Summary
              ecf_results = paths.values.flatten.map { |r| r[:ecf] }
              npq_results = paths.values.flatten.map { |r| r[:npq] }

              ecf_avg_latencies = ecf_results.map { |r| r[:latency][:avg] }
              ecf_avg_latency = ecf_avg_latencies.sum / ecf_avg_latencies.count
              ecf_max_latency = ecf_results.map { |r| r[:latency][:max] }.max
              ecf_total_requests = ecf_results.map { |r| r[:request][:count] }.sum
              ecf_req_per_sec = ecf_results.map { |r| r[:request][:per_second] }
              ecf_avg_req_per_sec = ecf_req_per_sec.sum / ecf_req_per_sec.count

              npq_avg_latencies = npq_results.map { |r| r[:latency][:avg] }
              npq_avg_latency = npq_avg_latencies.sum / npq_avg_latencies.count
              npq_max_latency = npq_results.map { |r| r[:latency][:max] }.max
              npq_total_requests = npq_results.map { |r| r[:request][:count] }.sum
              npq_req_per_sec = npq_results.map { |r| r[:request][:per_second] }
              npq_avg_req_per_sec = npq_req_per_sec.sum / npq_req_per_sec.count

              sheet.add_row ["", "ECF", "NPQ"]
              sheet.add_row ["Total requests", ecf_total_requests, npq_total_requests]
              sheet.add_row ["Avg req/s", ecf_avg_req_per_sec.round(0), npq_avg_req_per_sec.round(0)]
              sheet.add_row ["Avg latency across all requests", "#{ecf_avg_latency.round(0)}ms", "#{npq_avg_latency.round(0)}ms"]
              sheet.add_row ["Max latency across all requests", "#{ecf_max_latency.round(0)}ms", "#{npq_max_latency.round(0)}ms"]

              row_start = row_end + 2

              # Total requests pie chart
              sheet.add_chart(Axlsx::Pie3DChart, start_at: "G84", end_at: "Q104", title: sheet["A#{row_start + 1}"]) do |chart|
                chart.add_series data: sheet["B#{row_start + 1}:C#{row_start + 1}"], labels: sheet["B#{row_start}:C#{row_start}"], colors: %w[0000FF FF0000]
              end
            end
          end
        end

        p.serialize("results.xlsx")
      end
    end

  private

    def integer_to_excel_column(index)
      result = ""

      while index.positive?
        index, remainder = (index - 1).divmod(26)
        result.prepend((65 + remainder).chr)
      end

      result
    end

    def short_name(lead_provider)
      @short_names ||= {
        "Ambition Institute" => "Ambition",
        "Church of England" => "CoE",
        "Education Development Trust" => "EDT",
        "Teacher Development Trust" => "TDT",
        "National Institute of Teaching" => "NIT",
        "School-Led Network" => "SLN",
        "Best Practice Network" => "BPN",
        "University College London (UCL) Institute of Education" => "UCL",
      }

      @short_names[lead_provider] || lead_provider
    end

    def call_endpoints(lead_provider)
      endpoints.each do |method, paths|
        paths.each do |path, options|
          client = Client.new(lead_provider:, method:, path:, options:)

          client.make_requests do |ecf_result, npq_result, formatted_path, page|
            save_comparison!(lead_provider:, path: formatted_path, method:, page:, ecf_result:, npq_result:)
          end
        end
      end
    end

    def save_comparison!(lead_provider:, path:, method:, page:, ecf_result:, npq_result:)
      results[lead_provider.name] ||= {}
      results[lead_provider.name][method] ||= {}
      results[lead_provider.name][method]["#{path}#{page ? "#page-#{page}" : ""}"] = {
        ecf: ecf_result,
        npq: npq_result,
      }
    end

    def endpoints
      file = Rails.root.join(endpoints_file_path)

      raise EndpointsFileNotFoundError, "Endpoints file not found: #{endpoints_file_path}" unless File.exist?(file)

      YAML.load_file(file).with_indifferent_access
    end

    def lead_providers
      @lead_providers ||= LeadProvider.all
    end
  end
end
