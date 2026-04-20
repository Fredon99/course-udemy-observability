using System.Diagnostics.Metrics;
using OpenTelemetry.Exporter;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);
var metricCollectorUrl = builder.Configuration["OtelMetricCollector:Host"] ?? "";
var traceCollectorUrl = builder.Configuration["OtelTraceCollector:Host"] ?? "";

const string serviceName = "Order Service";
const string serviceVersion = "1.0.0";
var meterName = $"{serviceName}.meter";

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
app.Run();