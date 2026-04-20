using System.Diagnostics.Metrics;
using OpenTelemetry.Context.Propagation;
using OpenTelemetry.Exporter;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);
var metricCollectorUrl = builder.Configuration["OtelMetricCollector:Host"] ?? "";
var traceCollectorUrl = builder.Configuration["OtelTraceCollector:Host"] ?? "";

builder.Services.AddHttpClient();

const string serviceName = "Order Service";
const string serviceVersion = "1.0.0";
var meterName = $"{serviceName}.meter";

builder.Services.AddSingleton(sp => sp.GetRequiredService<TracerProvider>().GetTracer(serviceName));

builder.Services
    .AddMetrics()
    .AddOpenTelemetry()
    .WithMetrics(m =>
    {
        m.SetResourceBuilder(ResourceBuilder.CreateDefault()
                .AddService(serviceName, serviceVersion: serviceVersion))
            .AddMeter(meterName)
            .AddOtlpExporter(o =>
            {
                o.Protocol = OtlpExportProtocol.Grpc;
                o.Endpoint = new Uri("http://alloy:4317");
                o.TimeoutMilliseconds = 30000;
            })
            .AddConsoleExporter();
    })
    .WithTracing(t =>
    {
        t.AddSource(serviceName)
            .SetResourceBuilder(
                ResourceBuilder.CreateDefault()
                    .AddService(serviceName, serviceVersion: serviceVersion))
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddOtlpExporter(o =>
            {
                o.Protocol = OtlpExportProtocol.Grpc;
                o.Endpoint = new Uri("http://alloy:4317");
                o.TimeoutMilliseconds = 30000;
            })
            .AddConsoleExporter();
    });


var app = builder.Build();


app.MapGet("/", (HttpContext context, IMeterFactory metricFactory) =>
{
    #region Metric collection

    var meter = metricFactory?.Create(new MeterOptions(meterName));
    var otlOrderCount = meter?.CreateCounter<int>("otel_order");
    otlOrderCount?.Add(1);

    #endregion

    // Traces são capturados automaticamente pelo AddAspNetCoreInstrumentation()
    // Cada requisição HTTP gera um span automaticamente

    return "OK";
});


app.MapGet("/call-payment-service",
    async (Tracer tracer, IMeterFactory metricFactory, IHttpClientFactory httpClientFactory) =>
    {   
        #region Metric collection

        var meter = metricFactory.Create(new MeterOptions(meterName));
        var otlOrderCount = meter.CreateCounter<int>("otel_order");
        otlOrderCount.Add(1);

        #endregion

        #region trace

        using var httpSpan = tracer.StartActiveSpan("Making HTTP Call", SpanKind.Client);

        httpSpan.SetAttribute("comms", "api");
        httpSpan.SetAttribute("protocol", "http");
        httpSpan.SetStatus(Status.Ok);
       
        var paymentServiceUrl = "http://payment-service:8080";
        var httpClient = httpClientFactory.CreateClient();
        var paymentRequest = new HttpRequestMessage(HttpMethod.Get, paymentServiceUrl);

        // AddHttpClientInstrumentation() propagates the trace context (traceparent header)
        // automatically when httpClient.SendAsync() is called — no manual injection needed.
        try
        {
            Console.WriteLine($"Calling Payment Service at {paymentServiceUrl}");
            await httpClient.SendAsync(paymentRequest);
        }
        catch
        {
            return "Run the Payment Service First.";
        }

        #endregion

        return "OK";
    });

app.Run();