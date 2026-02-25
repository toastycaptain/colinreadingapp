# MediaConvert Module

MediaConvert does not require provisioning an endpoint resource in Terraform for MVP.
Rails should call `DescribeEndpoints` and cache the result.

This module keeps optional config placeholders (endpoint URL and job template name)
so environments can expose explicit values later without changing module contracts.
