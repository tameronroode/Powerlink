<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTaskRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'assigned_to' => 'required|exists:employees,id',
            'assigned_by' => 'required|exists:employees,id',
            'due_date' => 'nullable|date',
            'status' => 'required|string|in:open,in_progress,done,cancelled',
        ];
    }
}

